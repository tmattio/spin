/*
 * lTerm_windows_stubs.c
 * ---------------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 */

/* Windows specific stubs */

#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>

#if defined(_WIN32) || defined(_WIN64)

#include <lwt_unix.h>

/* +-----------------------------------------------------------------+
   | Codepage functions                                              |
   +-----------------------------------------------------------------+ */

CAMLprim value lt_windows_get_acp()
{
  return Val_int(GetACP());
}

CAMLprim value lt_windows_get_console_cp()
{
  return Val_int(GetConsoleCP());
}

CAMLprim value lt_windows_set_console_cp(value cp)
{
  if (!SetConsoleCP(Int_val(cp))) {
    win32_maperr(GetLastError());
    uerror("SetConsoleCP", Nothing);
  }
  return Val_unit;
}

CAMLprim value lt_windows_get_console_output_cp()
{
  return Val_int(GetConsoleOutputCP());
}

CAMLprim value lt_windows_set_console_output_cp(value cp)
{
  if (!SetConsoleOutputCP(Int_val(cp))) {
    win32_maperr(GetLastError());
    uerror("SetConsoleOutputCP", Nothing);
  }
  return Val_unit;
}

/* +-----------------------------------------------------------------+
   | Console input                                                   |
   +-----------------------------------------------------------------+ */

static WORD code_table[] = {
  VK_RETURN,
  VK_ESCAPE,
  VK_TAB,
  VK_UP,
  VK_DOWN,
  VK_LEFT,
  VK_RIGHT,
  VK_F1,
  VK_F2,
  VK_F3,
  VK_F4,
  VK_F5,
  VK_F6,
  VK_F7,
  VK_F8,
  VK_F9,
  VK_F10,
  VK_F11,
  VK_F12,
  VK_NEXT,
  VK_PRIOR,
  VK_HOME,
  VK_END,
  VK_INSERT,
  VK_DELETE,
  VK_BACK
};

struct job_read_console_input {
  struct lwt_unix_job job;
  HANDLE handle;
  INPUT_RECORD input;
  DWORD error_code;
};

#define Job_read_console_input_val(v) *(struct job_read_console_input**)Data_custom_val(v)

static void worker_read_console_input(struct job_read_console_input *job)
{
  DWORD event_count;
  INPUT_RECORD *input = &(job->input);
  WORD code;
  int i;
  DWORD bs;

  for (;;) {
    if (!ReadConsoleInputW(job->handle, input, 1, &event_count)) {
      job->error_code = GetLastError();
      return;
    }

    switch (input->EventType) {
    case KEY_EVENT:
      if (input->Event.KeyEvent.bKeyDown) {
        if (input->Event.KeyEvent.uChar.UnicodeChar)
          return;
        code = input->Event.KeyEvent.wVirtualKeyCode;
        for (i = 0; i < sizeof(code_table)/sizeof(code_table[0]); i++)
          if (code == code_table[i])
            return;
      }
      break;
    case MOUSE_EVENT: {
      bs = input->Event.MouseEvent.dwButtonState;
      if (!(input->Event.MouseEvent.dwEventFlags & MOUSE_MOVED) &&
          bs & (FROM_LEFT_1ST_BUTTON_PRESSED |
                FROM_LEFT_2ND_BUTTON_PRESSED |
                FROM_LEFT_3RD_BUTTON_PRESSED |
                FROM_LEFT_4TH_BUTTON_PRESSED |
                RIGHTMOST_BUTTON_PRESSED))
        return;
      break;
    }
    case WINDOW_BUFFER_SIZE_EVENT:
      return;
    }
  }
}

static value result_read_console_input(struct job_read_console_input *job)
{
  INPUT_RECORD * input;
  DWORD cks, bs;
  WORD code;
  int i;
  CAMLparam0();
  CAMLlocal3(result, x, y);
  int error_code = job->error_code;
  input = &(job->input);
  lwt_unix_free_job(&job->job);
  if (error_code) {
    win32_maperr(error_code);
    uerror("ReadConsoleInput", Nothing);
  }
  switch (input->EventType) {
  case KEY_EVENT: {
    result = caml_alloc(1, 0);
    x = caml_alloc_tuple(4);
    Field(result, 0) = x;
    cks = input->Event.KeyEvent.dwControlKeyState;
    Field(x, 0) = Val_bool((cks & LEFT_CTRL_PRESSED) | (cks & RIGHT_CTRL_PRESSED));
    Field(x, 1) = Val_bool((cks & LEFT_ALT_PRESSED) | (cks & RIGHT_ALT_PRESSED));
    Field(x, 2) = Val_bool(cks & SHIFT_PRESSED);
    code = input->Event.KeyEvent.wVirtualKeyCode;
    for (i = 0; i < sizeof(code_table)/sizeof(code_table[0]); i++)
      if (code == code_table[i]) {
        Field(x, 3) = Val_int(i);
        CAMLreturn(result);
      }
    y = caml_alloc_tuple(1);
    Field(y, 0) = Val_int(input->Event.KeyEvent.uChar.UnicodeChar);
    Field(x, 3) = y;
    CAMLreturn(result);
  }
  case MOUSE_EVENT: {
    result = caml_alloc(1, 1);
    x = caml_alloc_tuple(6);
    Field(result, 0) = x;
    cks = input->Event.MouseEvent.dwControlKeyState;
    Field(x, 0) = Val_bool((cks & LEFT_CTRL_PRESSED) | (cks & RIGHT_CTRL_PRESSED));
    Field(x, 1) = Val_bool((cks & LEFT_ALT_PRESSED) | (cks & RIGHT_ALT_PRESSED));
    Field(x, 2) = Val_bool(cks & SHIFT_PRESSED);
    Field(x, 4) = Val_int(input->Event.MouseEvent.dwMousePosition.Y);
    Field(x, 5) = Val_int(input->Event.MouseEvent.dwMousePosition.X);
    bs = input->Event.MouseEvent.dwButtonState;
    if (bs & FROM_LEFT_1ST_BUTTON_PRESSED)
      Field(x, 3) = Val_int(0);
    else if (bs & FROM_LEFT_2ND_BUTTON_PRESSED)
      Field(x, 3) = Val_int(1);
    else if (bs & FROM_LEFT_3RD_BUTTON_PRESSED)
      Field(x, 3) = Val_int(2);
    else if (bs & FROM_LEFT_4TH_BUTTON_PRESSED)
      Field(x, 3) = Val_int(3);
    else
      Field(x, 3) = Val_int(4);
    CAMLreturn(result);
  }
  case WINDOW_BUFFER_SIZE_EVENT:
    CAMLreturn(Val_int(0));
  }
  CAMLreturn(Val_int(0));
}

CAMLprim value lt_windows_read_console_input_job(value val_fd)
{
  CAMLparam1(val_fd);
  LWT_UNIX_INIT_JOB(job, read_console_input, 0);
  job->handle = Handle_val(val_fd);
  job->error_code = 0;
  CAMLreturn(lwt_unix_alloc_job(&(job->job)));
}

/* +-----------------------------------------------------------------+
   | Console informations                                            |
   +-----------------------------------------------------------------+ */

CAMLprim value lt_windows_get_console_screen_buffer_info(value val_fd)
{
  CAMLparam1(val_fd);
  CAMLlocal2(result, x);

  CONSOLE_SCREEN_BUFFER_INFO info;
  int color;

  if (!GetConsoleScreenBufferInfo(Handle_val(val_fd), &info)) {
    win32_maperr(GetLastError());
    uerror("GetConsoleScreenBufferInfo", Nothing);
  }

  result = caml_alloc_tuple(5);

  x = caml_alloc_tuple(2);
  Field(x, 0) = Val_int(info.dwSize.Y);
  Field(x, 1) = Val_int(info.dwSize.X);
  Field(result, 0) = x;

  x = caml_alloc_tuple(2);
  Field(x, 0) = Val_int(info.dwCursorPosition.Y);
  Field(x, 1) = Val_int(info.dwCursorPosition.X);
  Field(result, 1) = x;

  x = caml_alloc_tuple(2);
  color = 0;
  if (info.wAttributes & FOREGROUND_RED) color |= 1;
  if (info.wAttributes & FOREGROUND_GREEN) color |= 2;
  if (info.wAttributes & FOREGROUND_BLUE) color |= 4;
  if (info.wAttributes & FOREGROUND_INTENSITY) color |= 8;
  Field(x, 0) = Val_int(color);
  color = 0;
  if (info.wAttributes & BACKGROUND_RED) color |= 1;
  if (info.wAttributes & BACKGROUND_GREEN) color |= 2;
  if (info.wAttributes & BACKGROUND_BLUE) color |= 4;
  if (info.wAttributes & BACKGROUND_INTENSITY) color |= 8;
  Field(x, 1) = Val_int(color);
  Field(result, 2) = x;

  x = caml_alloc_tuple(4);
  Field(x, 0) = Val_int(info.srWindow.Top);
  Field(x, 1) = Val_int(info.srWindow.Left);
  Field(x, 2) = Val_int(info.srWindow.Bottom + 1);
  Field(x, 3) = Val_int(info.srWindow.Right + 1);
  Field(result, 3) = x;

  x = caml_alloc_tuple(2);
  Field(x, 0) = Val_int(info.dwMaximumWindowSize.Y);
  Field(x, 1) = Val_int(info.dwMaximumWindowSize.X);
  Field(result, 4) = x;

  CAMLreturn(result);
}

/* +-----------------------------------------------------------------+
   | Console mode                                                    |
   +-----------------------------------------------------------------+ */

CAMLprim value lt_windows_get_console_mode(value val_fd)
{
  DWORD mode;
  value result;

  if (!GetConsoleMode(Handle_val(val_fd), &mode)) {
    win32_maperr(GetLastError());
    uerror("GetConsoleMode", Nothing);
  }

  result = caml_alloc_tuple(7);
  Field(result, 0) = Val_bool(mode & ENABLE_ECHO_INPUT);
  Field(result, 1) = Val_bool(mode & ENABLE_INSERT_MODE);
  Field(result, 2) = Val_bool(mode & ENABLE_LINE_INPUT);
  Field(result, 3) = Val_bool(mode & ENABLE_MOUSE_INPUT);
  Field(result, 4) = Val_bool(mode & ENABLE_PROCESSED_INPUT);
  Field(result, 5) = Val_bool(mode & ENABLE_QUICK_EDIT_MODE);
  Field(result, 6) = Val_bool(mode & ENABLE_WINDOW_INPUT);
  return result;
}

CAMLprim value lt_windows_set_console_mode(value val_fd, value val_mode)
{
  DWORD mode = 0;

  if (Bool_val(Field(val_mode, 0))) mode |= ENABLE_ECHO_INPUT;
  if (Bool_val(Field(val_mode, 1))) mode |= ENABLE_INSERT_MODE;
  if (Bool_val(Field(val_mode, 2))) mode |= ENABLE_LINE_INPUT;
  if (Bool_val(Field(val_mode, 3))) mode |= ENABLE_MOUSE_INPUT;
  if (Bool_val(Field(val_mode, 4))) mode |= ENABLE_PROCESSED_INPUT;
  if (Bool_val(Field(val_mode, 5))) mode |= ENABLE_QUICK_EDIT_MODE;
  if (Bool_val(Field(val_mode, 6))) mode |= ENABLE_WINDOW_INPUT;

  if (!SetConsoleMode(Handle_val(val_fd), mode)) {
    win32_maperr(GetLastError());
    uerror("SetConsoleMode", Nothing);
  }
  return Val_unit;
}

/* +-----------------------------------------------------------------+
   | Cursor                                                          |
   +-----------------------------------------------------------------+ */

CAMLprim value lt_windows_get_console_cursor_info(value val_fd)
{
  CONSOLE_CURSOR_INFO info;
  value result;
  if (!GetConsoleCursorInfo(Handle_val(val_fd), &info)) {
    win32_maperr(GetLastError());
    uerror("GetConsoleCursorInfo", Nothing);
  }
  result = caml_alloc_tuple(2);
  Field(result, 0) = Val_int(info.dwSize);
  Field(result, 1) = Val_bool(info.bVisible);
  return result;
}

CAMLprim value lt_windows_set_console_cursor_info(value val_fd, value val_size, value val_visible)
{
  CONSOLE_CURSOR_INFO info;
  info.dwSize = Int_val(val_size);
  info.bVisible = Bool_val(val_visible);
  if (!SetConsoleCursorInfo(Handle_val(val_fd), &info)) {
    win32_maperr(GetLastError());
    uerror("SetConsoleCursorInfo", Nothing);
  }
  return Val_unit;
}

CAMLprim value lt_windows_set_console_cursor_position(value val_fd, value val_coord)
{
  COORD coord;
  coord.X = Int_val(Field(val_coord, 1));
  coord.Y = Int_val(Field(val_coord, 0));
  if (!SetConsoleCursorPosition(Handle_val(val_fd), coord)) {
    win32_maperr(GetLastError());
    uerror("SetConsoleCursorPosition", Nothing);
  }
  return Val_unit;
}

/* +-----------------------------------------------------------------+
   | Text attributes                                                 |
   +-----------------------------------------------------------------+ */

CAMLprim value lt_windows_set_console_text_attribute(value val_fd, value val_attrs)
{
  int fg = Int_val(Field(val_attrs, 0));
  int bg = Int_val(Field(val_attrs, 1));
  WORD attrs = 0;

  if (fg & 1) attrs |= FOREGROUND_RED;
  if (fg & 2) attrs |= FOREGROUND_GREEN;
  if (fg & 4) attrs |= FOREGROUND_BLUE;
  if (fg & 8) attrs |= FOREGROUND_INTENSITY;

  if (bg & 1) attrs |= BACKGROUND_RED;
  if (bg & 2) attrs |= BACKGROUND_GREEN;
  if (bg & 4) attrs |= BACKGROUND_BLUE;
  if (bg & 8) attrs |= BACKGROUND_INTENSITY;

  if (!SetConsoleTextAttribute(Handle_val(val_fd), attrs)) {
    win32_maperr(GetLastError());
    uerror("SetConsoleTextAttribute", Nothing);
  }
  return Val_unit;
}

/* +-----------------------------------------------------------------+
   | Rendering                                                       |
   +-----------------------------------------------------------------+ */

CAMLprim value lt_windows_write_console_output(value val_fd, value val_chars, value val_size, value val_coord, value val_rect)
{
  CAMLparam5(val_fd, val_chars, val_size, val_coord, val_rect);
  CAMLlocal1(result);

  value line, src;
  int fg, bg;
  WORD attrs;
  int lines = Int_val(Field(val_size, 0));
  int columns = Int_val(Field(val_size, 1));
  COORD size;
  COORD coord;
  SMALL_RECT rect;

  /* Convert characters */
  CHAR_INFO *buffer = (CHAR_INFO*)lwt_unix_malloc(lines * columns * sizeof (CHAR_INFO));
  int l, c;
  CHAR_INFO *dst = buffer;
  for (l = 0; l < lines; l++) {
    line = Field(val_chars, l);
    for (c = 0; c < columns; c++) {
      src = Field(line, c);
      dst->Char.UnicodeChar = Int_val(Field(src, 0));
      fg = Int_val(Field(src, 1));
      bg = Int_val(Field(src, 2));
      attrs = 0;
      if (fg & 1) attrs |= FOREGROUND_RED;
      if (fg & 2) attrs |= FOREGROUND_GREEN;
      if (fg & 4) attrs |= FOREGROUND_BLUE;
      if (fg & 8) attrs |= FOREGROUND_INTENSITY;
      if (bg & 1) attrs |= BACKGROUND_RED;
      if (bg & 2) attrs |= BACKGROUND_GREEN;
      if (bg & 4) attrs |= BACKGROUND_BLUE;
      if (bg & 8) attrs |= BACKGROUND_INTENSITY;
      dst->Attributes = attrs;
      dst++;
    }
  }

  size.X = Int_val(Field(val_size, 1));
  size.Y = Int_val(Field(val_size, 0));
  coord.X = Int_val(Field(val_coord, 1));
  coord.Y = Int_val(Field(val_coord, 0));
  rect.Top = Int_val(Field(val_rect, 0));
  rect.Left = Int_val(Field(val_rect, 1));
  rect.Bottom = Int_val(Field(val_rect, 2)) - 1;
  rect.Right = Int_val(Field(val_rect, 3)) - 1;

  if (!WriteConsoleOutputW(Handle_val(val_fd), buffer, size, coord, &rect)) {
    free(buffer);
    win32_maperr(GetLastError());
    uerror("WriteConsoleOutput", Nothing);
  }
  free(buffer);

  result = caml_alloc_tuple(4);
  Field(result, 0) = Val_int(rect.Top);
  Field(result, 1) = Val_int(rect.Left);
  Field(result, 2) = Val_int(rect.Bottom + 1);
  Field(result, 3) = Val_int(rect.Right + 1);
  CAMLreturn(result);
}

/* +-----------------------------------------------------------------+
   | Filling                                                         |
   +-----------------------------------------------------------------+ */

CAMLprim value lt_windows_fill_console_output_character(value val_fd, value val_char, value val_count, value val_coord)
{
  COORD coord;
  DWORD written;

  coord.X = Int_val(Field(val_coord, 1));
  coord.Y = Int_val(Field(val_coord, 0));

  if (!FillConsoleOutputCharacter(Handle_val(val_fd), Int_val(val_char), Int_val(val_count), coord, &written)) {
    win32_maperr(GetLastError());
    uerror("FillConsoleOutputCharacter", Nothing);
  }

  return Val_int(written);
}

#else

/* +-----------------------------------------------------------------+
   | For unix                                                        |
   +-----------------------------------------------------------------+ */

#include <lwt_unix.h>

#define NA(name, feature)                       \
  CAMLprim value lt_windows_##name()            \
  {                                             \
    lwt_unix_not_available(feature);            \
    return Val_unit;                            \
  }

NA(get_acp, "GetACP")
NA(get_console_cp, "GetConsoleCP")
NA(set_console_cp, "SetConsoleCP")
NA(get_console_output_cp, "GetConsoleOutputCP")
NA(set_console_output_cp, "SetConsoleOutputCP")
NA(read_console_input_job, "ReadConsoleInput")
NA(read_console_input_result, "ReadConsoleInput")
NA(read_console_input_free, "ReadConsoleInput")
NA(set_console_text_attribute, "SetConsoleTextAttribute")
NA(get_console_screen_buffer_info, "GetConsoleScreenBufferInfo")
NA(get_console_cursor_info, "GetConsoleCursorInfo")
NA(set_console_cursor_info, "SetConsoleCursorInfo")
NA(write_console_output, "WriteConsoleOutput")
NA(set_console_cursor_position, "SetConsoleCursorPosition")
NA(get_console_mode, "GetConsoleMode")
NA(set_console_mode, "SetConsoleMode")
NA(fill_console_output_character, "FillConsoleOutputCharacter")

#endif
