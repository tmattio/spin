/* Ansi; windows API calls

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
   LICENSE for more details.
*/

#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <stdio.h>
#include <string.h>
#include <windows.h>

#include "io.h"

/* From otherlibs/win32unix/channels.c */
extern long _get_osfhandle(int);
#define HANDLE_OF_CHAN(vchan) ((HANDLE)_get_osfhandle(Channel(vchan)->fd))

static HANDLE hStdout;
static CONSOLE_SCREEN_BUFFER_INFO *csbiInfo = NULL;

void raise_error(char *fname, char *msg) {
  CAMLparam0();
  CAMLlocal2(vfname, vmsg);
  static value *exn = NULL;
  value args[2];

  if (exn == NULL) {
    /* First time around, look up by name */
    exn = caml_named_value("Ansi.Error");
  }
  vfname = caml_copy_string(fname);
  vmsg = caml_copy_string(msg);
  args[0] = vfname;
  args[1] = vmsg;
  caml_raise_with_args(*exn, 2, args);
  CAMLnoreturn;
}

void exn_of_error(char *fname, BOOL cond) {
  CAMLparam0();
  CAMLlocal2(vfname, vmsg);
  char *msg, *p;
  LPVOID lpMsgBuf;
  static value *exn = NULL;
  value args[2];

  if (cond) {
    if (exn == NULL) {
      /* First time around, look up by name */
      exn = caml_named_value("Ansi.Error");
    }
    FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
                      FORMAT_MESSAGE_IGNORE_INSERTS,
                  NULL, GetLastError(),
                  MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPTSTR)&lpMsgBuf,
                  0, NULL);
    vfname = caml_copy_string(fname);
    msg = (char *)lpMsgBuf;
    p = msg + strlen(msg) - 1;
    while (*p == '\n' || *p == '\r') {
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

#define SET_CSBI(fname)                                                  \
  if (!csbiInfo) {                                                       \
    hStdout = GetStdHandle(STD_OUTPUT_HANDLE);                           \
    if (hStdout == INVALID_HANDLE_VALUE) {                               \
      raise_error(fname, "Invalid stdout handle");                       \
    }                                                                    \
    exn_of_error(fname, !GetConsoleScreenBufferInfo(hStdout, csbiInfo)); \
  }

#define SET_STYLE(fname)                                                     \
  CAMLexport value Ansi_##fname(value vchan, value vcode) {          \
    HANDLE h = HANDLE_OF_CHAN(vchan);                                        \
    int code = Int_val(vcode);                                               \
                                                                             \
    exn_of_error("Ansi." #fname, !SetConsoleTextAttribute(h, code)); \
    return Val_unit;                                                         \
  }

SET_STYLE(set_style)
SET_STYLE(unset_style)

CAMLexport value Ansi_get_style(value vchan) {
  HANDLE h = HANDLE_OF_CHAN(vchan);
  CONSOLE_SCREEN_BUFFER_INFO info;

  /* To save the previous info when setting style */
  exn_of_error("Ansi.set_style", !GetConsoleScreenBufferInfo(h, &info));

  return (Val_int(info.wAttributes));
}

CAMLexport value Ansi_pos(value vunit) {
  CAMLparam1(vunit);
  CAMLlocal1(vpos);
  SMALL_RECT w;
  SHORT x, y;

  exn_of_error("Ansi.pos_cursor",
               !GetConsoleScreenBufferInfo(hStdout, csbiInfo));
  w = csbiInfo->srWindow;
  /* The topmost left character has pos (1,1) */
  x = csbiInfo->dwCursorPosition.X - w.Left + 1;
  y = csbiInfo->dwCursorPosition.Y - w.Top + 1;

  vpos = caml_alloc_tuple(2);
  Store_field(vpos, 0, Val_int(x));
  Store_field(vpos, 1, Val_int(y));
  CAMLreturn(vpos);
}

CAMLexport value Ansi_size(value vunit) {
  CAMLparam1(vunit);
  CAMLlocal1(vsize);
  SMALL_RECT w;

  /* Update the global var as the terminal may have been be resized */
  SET_CSBI("Ansi.size");
  exn_of_error("Ansi.size",
               !GetConsoleScreenBufferInfo(hStdout, csbiInfo));
  w = csbiInfo->srWindow;

  vsize = caml_alloc_tuple(2);
  Store_field(vsize, 0, Val_int(w.Right - w.Left + 1));
  Store_field(vsize, 1, Val_int(w.Bottom - w.Top + 1));

  CAMLreturn(vsize);
}

CAMLexport value Ansi_resize(value vx, value vy) {
  /* noalloc */
  COORD dwSize;
  dwSize.X = Int_val(vx);
  dwSize.Y = Int_val(vy);
  exn_of_error("Ansi.resize",
               !SetConsoleScreenBufferSize(hStdout, dwSize));
  return Val_unit;
}

CAMLexport value Ansi_SetCursorPosition(value vx, value vy) {
  COORD c;
  SMALL_RECT w;

  SET_CSBI("Ansi.set_cursor");
  exn_of_error("Ansi.set_cursor",
               !GetConsoleScreenBufferInfo(hStdout, csbiInfo));
  /* The top lefmost coordinate is (1,1) for Ansi while it is
   * (0,0) for windows. */
  w = csbiInfo->srWindow;
  c.X = Int_val(vx) - 1 + w.Left;
  c.Y = Int_val(vy) - 1 + w.Top;

  // very subtle debugging method...
  fprintf(stderr, "vx,vy = %d,%d --> [c.X,Y = %d,%d ; L %d R %d T %d B %d]\n",
          Int_val(vx), Int_val(vy), c.X, c.Y, w.Left, w.Right, w.Top, w.Bottom);

  if (c.X > w.Right) c.X = w.Right;
  if (c.Y > w.Bottom) c.Y = w.Bottom;
  exn_of_error("Ansi.set_cursor",
               !SetConsoleCursorPosition(hStdout, c));
  return Val_unit;
}

CAMLexport value Ansi_FillConsoleOutputCharacter(value vchan, value vc,
                                                         value vlen, value vx,
                                                         value vy) {
  CAMLparam1(vchan);
  HANDLE h = HANDLE_OF_CHAN(vchan);
  int NumberOfCharsWritten;
  COORD dwWriteCoord;

  SET_CSBI("Ansi.erase");
  exn_of_error("Ansi.erase",
               !GetConsoleScreenBufferInfo(hStdout, csbiInfo));
  dwWriteCoord.X = Int_val(vx) - 1 + csbiInfo->srWindow.Left;
  dwWriteCoord.Y = Int_val(vy) - 1 + csbiInfo->srWindow.Top;
  exn_of_error("Ansi.erase", !FillConsoleOutputCharacter(
                                         h, Int_val(vc), Int_val(vlen),
                                         dwWriteCoord, &NumberOfCharsWritten));
  CAMLreturn(Val_int(NumberOfCharsWritten));
}

CAMLexport value Ansi_Scroll(value vx) {
  /* noalloc */
  INT x = Int_val(vx);
  SMALL_RECT srctScrollRect, srctClipRect;
  CHAR_INFO chiFill;
  COORD coordDest;

  SET_CSBI("Ansi.scroll");
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
  chiFill.Attributes = FOREGROUND_RED | FOREGROUND_INTENSITY;
  chiFill.Char.AsciiChar = (char)' ';

  exn_of_error(
      "Ansi.scroll",
      !ScrollConsoleScreenBuffer(hStdout,          // screen buffer handle
                                 &srctScrollRect,  // scrolling rectangle
                                 &srctClipRect,    // clipping rectangle
                                 coordDest,        // top left destination cell
                                 &chiFill));       // fill character and color
  return Val_unit;
}
