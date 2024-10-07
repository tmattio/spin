/* ANSITerminal; windows API calls

   Allow colors, cursor movements, erasing,... under Unix and DOS shells.
   *********************************************************************

   Copyright 2010 by Christophe Troestler <Christophe.Troestler@umons.ac.be>
   http://math.umons.ac.be/an/software/

   Copyright 2010 by Vincent Hugot
   vincent.hugot@gmail.com
   www.vincent-hugot.com

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public License
   version 2.1 as published by the Free Software Foundation, with the
   special exception on linking described in file LICENSE.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details.CAMLexport
*/

#if defined ( _WIN32 ) || defined ( _WIN64 )
#define BUILT_ON_WINDOWS
#endif



#include <stdio.h>
#include <string.h>
#define CAML_INTERNALS
#include <caml/io.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/callback.h>
#include <caml/fail.h>

#ifdef BUILT_ON_WINDOWS
#include <windows.h>
#include <io.h>

/* From otherlibs/win32unix/channels.c */
#define HANDLE_OF_CHAN(vchan) ((HANDLE) _get_osfhandle(Channel(vchan)->fd))

HANDLE hStdout;
CONSOLE_SCREEN_BUFFER_INFO *csbiInfo = NULL;

void raise_error(char *fname, char *msg)
{
  CAMLparam0();
  CAMLlocal2(vfname, vmsg);
  static const value *exn = NULL;
  value args[2];
  
  if (exn == NULL) {
    /* First time around, look up by name */
    exn = caml_named_value("ANSITerminal.Error");
  }
  vfname = caml_copy_string(fname);
  vmsg = caml_copy_string(msg);
  args[0] = vfname;
  args[1] = vmsg;
  caml_raise_with_args(*exn, 2, args);
  CAMLnoreturn;
}

void exn_of_error(char *fname, BOOL cond)
{
  CAMLparam0();
  CAMLlocal2(vfname, vmsg);
  char *msg, *p;
  LPVOID lpMsgBuf;
  static const value *exn = NULL;
  value args[2];
  
  if (cond) {
    if (exn == NULL) {
      /* First time around, look up by name */
      exn = caml_named_value("ANSITerminal.Error");
    }
    FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER |
                  FORMAT_MESSAGE_FROM_SYSTEM |
                  FORMAT_MESSAGE_IGNORE_INSERTS,
                  NULL,
                  GetLastError(),
                  MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                  (LPTSTR) &lpMsgBuf,
                  0, NULL);
    vfname = caml_copy_string(fname);
    msg = (char *) lpMsgBuf;
    p = msg + strlen(msg) - 1; 
    while(*p == '\n' || *p == '\r') {
      *p = '\0';
      p--;
    }
    vmsg = caml_copy_string(msg);
    LocalFree(lpMsgBuf);
    args[0] = vfname;
    args[1] = vmsg;
    caml_raise_with_args(*exn, 2, args);
  }
  CAMLreturn0;
}



#define SET_CSBI(fname)                                               \
  if (! csbiInfo) {                                                   \
    csbiInfo = ( CONSOLE_SCREEN_BUFFER_INFO *)malloc (sizeof(CONSOLE_SCREEN_BUFFER_INFO)); \
    hStdout = GetStdHandle(STD_OUTPUT_HANDLE);                        \
    if (hStdout == INVALID_HANDLE_VALUE) {                            \
      raise_error(fname, "Invalid stdout handle");                    \
    }                                                                 \
    exn_of_error(fname,                                               \
                 ! GetConsoleScreenBufferInfo(hStdout, csbiInfo));    \
  }


#define SET_STYLE(fname)                                                \
  CAMLexport                                                            \
  value ANSITerminal_ ## fname(value vchan, value vcode)                \
  {                                                                     \
  HANDLE h = HANDLE_OF_CHAN(vchan);                                     \
  int code = Int_val(vcode);                                            \
                                                                        \
  exn_of_error("ANSITerminal." #fname,                                  \
               ! SetConsoleTextAttribute(h, code));                     \
  return Val_unit;                                                      \
  }

SET_STYLE(set_style)
SET_STYLE(unset_style)

CAMLexport
value ANSITerminal_get_style(value vchan)
{
  HANDLE h = HANDLE_OF_CHAN(vchan);
  CONSOLE_SCREEN_BUFFER_INFO info;

  /* To save the previous info when setting style */
  exn_of_error("ANSITerminal.set_style",
               ! GetConsoleScreenBufferInfo(h, &info));
  
  return(Val_int(info.wAttributes));
}


CAMLexport
value ANSITerminal_pos(value vunit)
{
  CAMLparam1(vunit);
  CAMLlocal1(vpos);
  SMALL_RECT w;
  SHORT x, y;

  SET_CSBI("ANSITerminal.pos");
  exn_of_error("ANSITerminal.pos_cursor",
               ! GetConsoleScreenBufferInfo(hStdout, csbiInfo));
  w = csbiInfo->srWindow;
  /* The topmost left character has pos (1,1) */
  x = csbiInfo->dwCursorPosition.X - w.Left + 1;
  y = csbiInfo->dwCursorPosition.Y - w.Top + 1;

  vpos = caml_alloc_tuple(2);
  Store_field(vpos, 0, Val_int(x));
  Store_field(vpos, 1, Val_int(y));
  CAMLreturn(vpos);
}

CAMLexport
value ANSITerminal_size(value vunit)
{
  CAMLparam1(vunit);
  CAMLlocal1(vsize);
  SMALL_RECT w;

  /* Update the global var as the terminal may have been be resized */
  SET_CSBI("ANSITerminal.size");
  exn_of_error("ANSITerminal.size",
               ! GetConsoleScreenBufferInfo(hStdout, csbiInfo));
  w = csbiInfo->srWindow;

  vsize = caml_alloc_tuple(2);
  Store_field(vsize, 0, Val_int(w.Right - w.Left + 1));
  Store_field(vsize, 1, Val_int(w.Bottom - w.Top + 1));

  CAMLreturn(vsize);
}

CAMLexport
value ANSITerminal_resize(value vx, value vy)
{
  /* noalloc */
  COORD dwSize;
  dwSize.X = Int_val(vx);
  dwSize.Y = Int_val(vy);
  exn_of_error("ANSITerminal.resize",
               ! SetConsoleScreenBufferSize(hStdout, dwSize));
  return Val_unit;
}


CAMLexport
value ANSITerminal_SetCursorPosition(value vx, value vy)
{
  COORD c;
  SMALL_RECT w;

  SET_CSBI("ANSITerminal.set_cursor");
  exn_of_error("ANSITerminal.set_cursor",
               ! GetConsoleScreenBufferInfo(hStdout, csbiInfo));
  /* The top lefmost coordinate is (1,1) for ANSITerminal while it is
   * (0,0) for windows. */
  w = csbiInfo->srWindow;
  c.X = Int_val(vx) - 1 + w.Left;
  c.Y = Int_val(vy) - 1 + w.Top;

  // very subtle debugging method...
  // fprintf(stderr,"vx,vy = %d,%d --> [c.X,Y = %d,%d ; L %d R %d T %d B %d]\n", 
  //        Int_val(vx),Int_val(vy), c.X, c.Y, w.Left, w.Right, w.Top, w.Bottom);

  if (c.X > w.Right) c.X = w.Right;
  if (c.Y > w.Bottom) c.Y = w.Bottom;
  exn_of_error("ANSITerminal.set_cursor",
               ! SetConsoleCursorPosition(hStdout, c));
  return Val_unit;
}

CAMLexport
value ANSITerminal_ShowCursor(value vunit)
{
  CONSOLE_CURSOR_INFO cursorInfo;
  HANDLE hStdout = GetStdHandle(STD_OUTPUT_HANDLE);

  GetConsoleCursorInfo(hStdout, &cursorInfo);
  cursorInfo.bVisible = TRUE;
  SetConsoleCursorInfo(hStdout, &cursorInfo);

  return Val_unit;
}

CAMLexport
value ANSITerminal_HideCursor(value vunit)
{
  CONSOLE_CURSOR_INFO cursorInfo;
  HANDLE hStdout = GetStdHandle(STD_OUTPUT_HANDLE);

  GetConsoleCursorInfo(hStdout, &cursorInfo);
  cursorInfo.bVisible = FALSE;
  SetConsoleCursorInfo(hStdout, &cursorInfo);

  return Val_unit;
}

CAMLexport
value ANSITerminal_FillConsoleOutputCharacter(
  value vchan, value vc, value vlen, value vx, value vy)
{
  CAMLparam1(vchan);
  HANDLE h = HANDLE_OF_CHAN(vchan);
  DWORD NumberOfCharsWritten;
  COORD dwWriteCoord;

  SET_CSBI("ANSITerminal.erase");
  exn_of_error("ANSITerminal.erase",
               ! GetConsoleScreenBufferInfo(hStdout, csbiInfo));
  dwWriteCoord.X = Int_val(vx) - 1 + csbiInfo->srWindow.Left;
  dwWriteCoord.Y = Int_val(vy) - 1 + csbiInfo->srWindow.Top;
  exn_of_error("ANSITerminal.erase",
               !FillConsoleOutputCharacter(h, Int_val(vc), Int_val(vlen),
                                           dwWriteCoord,
                                           &NumberOfCharsWritten));
  CAMLreturn(Val_int(NumberOfCharsWritten));
}


CAMLexport
value ANSITerminal_Scroll(value vx)
{
  /* noalloc */
  INT x = Int_val(vx);
  SMALL_RECT srctScrollRect, srctClipRect;
  CHAR_INFO chiFill;
  COORD coordDest;

  SET_CSBI("ANSITerminal.scroll");
  srctScrollRect.Left = 0;
  srctScrollRect.Top = 1;
  srctScrollRect.Right = csbiInfo->dwSize.X - x;
  srctScrollRect.Bottom = csbiInfo->dwSize.Y - x;

  // The destination for the scroll rectangle is one row up.
  coordDest.X = 0;
  coordDest.Y = 0;

  // The clipping rectangle is the same as the scrolling rectangle.
  // The destination row is left unchanged.
  srctClipRect = srctScrollRect;

  // Set the fill character and attributes.
  chiFill.Attributes = FOREGROUND_RED|FOREGROUND_INTENSITY;
  chiFill.Char.AsciiChar = (char) ' ';

  exn_of_error("ANSITerminal.scroll",
               ! ScrollConsoleScreenBuffer(
                 hStdout,         // screen buffer handle
                 &srctScrollRect, // scrolling rectangle
                 &srctClipRect,   // clipping rectangle
                 coordDest,       // top left destination cell
                 &chiFill));      // fill character and color
  return Val_unit;
}

#else

#define NO_UNIX_VERSION(f_name)						\
	CAMLexport							\
	value ANSITerminal_## f_name(value vchan, value vcode)		\
	{								\
	     caml_failwith("ANSITerminal: Windows stubs not compiled"); \
	}

NO_UNIX_VERSION(set_style);
NO_UNIX_VERSION(unset_style);
NO_UNIX_VERSION(get_style);
NO_UNIX_VERSION(pos);
NO_UNIX_VERSION(size);
NO_UNIX_VERSION(resize);
NO_UNIX_VERSION(SetCursorPosition);
NO_UNIX_VERSION(FillConsoleOutputCharacter);
NO_UNIX_VERSION(Scroll);
NO_UNIX_VERSION(ShowCursor);
NO_UNIX_VERSION(HideCursor);


#endif

#ifndef BUILT_ON_WINDOWS
#include <sys/ioctl.h>
#include <termios.h>
#endif

/* Based on http://www.ohse.de/uwe/software/resize.c.html */
/* Inquire actual terminal size (this it what the kernel thinks - not
 * was the user on the over end of the phone line has really). */
CAMLexport
value ANSITerminal_term_size(value vfd)
{
  CAMLparam1(vfd);
  CAMLlocal1(vsize);
  int fd = Int_val(vfd);
  int x, y;
  
#ifdef TIOCGSIZE
  struct ttysize win;
#elif defined(TIOCGWINSZ)
  struct winsize win;
#endif

#ifdef TIOCGSIZE
  if (ioctl(fd, TIOCGSIZE, &win))
    caml_failwith("ANSITerminal.size");
  x = win.ts_cols;
  y = win.ts_lines;
#elif defined TIOCGWINSZ
  if (ioctl(fd, TIOCGWINSZ, &win))
    caml_failwith("ANSITerminal.size");
  x = win.ws_col;
  y = win.ws_row;
#else
  {
    const char *s;
    s = getenv("LINES");
    if (s)
      y = strtol(s,NULL,10);
    else
      y = 25;
    s = getenv("COLUMNS");
    if (s)
      x = strtol(s,NULL,10);
    else
      x = 80;
  }
#endif

  vsize = caml_alloc_tuple(2);
  Store_field(vsize, 0, Val_int(x));
  Store_field(vsize, 1, Val_int(y));
  CAMLreturn(vsize);
}