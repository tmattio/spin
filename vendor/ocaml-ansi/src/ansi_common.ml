(* Copyright 2004 by Troestler Christophe Christophe.Troestler(at)umons.ac.be

   This library is free software; you can redistribute it and/or modify it under
   the terms of the GNU Lesser General Public License version 3 as published by
   the Free Software Foundation, with the special exception on linking described
   in file LICENSE.

   This library is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
   FOR A PARTICULAR PURPOSE. See the file LICENSE for more details. *)

let autoreset = ref true

let set_autoreset b = autoreset := b

type color =
  | Black
  | Red
  | Green
  | Yellow
  | Blue
  | Magenta
  | Cyan
  | White
  | Bright_black
  | Bright_red
  | Bright_green
  | Bright_yellow
  | Bright_blue
  | Bright_magenta
  | Bright_cyan
  | Bright_white
  | Default

type style =
  | Reset
  | Bold
  | Underlined
  | Blink
  | Inverse
  | Hidden
  | Foreground of color
  | Background of color

let black = Foreground Black

let red = Foreground Red

let green = Foreground Green

let yellow = Foreground Yellow

let blue = Foreground Blue

let magenta = Foreground Magenta

let cyan = Foreground Cyan

let white = Foreground White

let bright_black = Foreground Bright_black

let bright_red = Foreground Bright_red

let bright_green = Foreground Bright_green

let bright_yellow = Foreground Bright_yellow

let bright_blue = Foreground Bright_blue

let bright_magenta = Foreground Bright_magenta

let bright_cyan = Foreground Bright_cyan

let bright_white = Foreground Bright_white

let default = Foreground Default

let bg_black = Background Black

let bg_red = Background Red

let bg_green = Background Green

let bg_yellow = Background Yellow

let bg_blue = Background Blue

let bg_magenta = Background Magenta

let bg_cyan = Background Cyan

let bg_white = Background White

let bg_bright_black = Background Bright_black

let bg_bright_red = Background Bright_red

let bg_bright_green = Background Bright_green

let bg_bright_yellow = Background Bright_yellow

let bg_bright_blue = Background Bright_blue

let bg_bright_magenta = Background Bright_magenta

let bg_bright_cyan = Background Bright_cyan

let bg_bright_white = Background Bright_white

let bg_default = Background Default

type loc =
  | Eol
  | Above
  | Below
  | Screen

let bold = Bold

let underlined = Underlined

let blink = Blink

let inverse = Inverse

let hidden = Hidden
