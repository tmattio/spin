module Make (LiteralIntf: LiteralIntf.Type) = struct
  open LTerm_geom

  class t = LTerm_widget_base_impl.t

  exception Out_of_range

  let rec insert x l n =
    if n < 0 then
      raise Out_of_range
    else if n = 0 then
      x :: l
    else
      match l with
        | [] ->
            raise Out_of_range
        | y :: l ->
            y :: insert x l (n - 1)

  type box_child = {
    widget : t;
    expand : bool;
    mutable length : int;
  }

  class type box = object
    inherit t
    method add : ?position : int -> ?expand : bool -> #t -> unit
    method remove : #t -> unit
  end

  class virtual abox rc = object(self)
    inherit t rc as super

    val mutable children = []
    method! children = List.map (fun child -> child.widget) children

    val mutable size_request = { rows = 0; cols = 0 }
    method! size_request = size_request

    method private virtual compute_allocations : unit
      (* Compute sizes of children. *)

    method private virtual compute_size_request : unit
      (* Compute the size request. *)

    method! set_allocation rect =
      super#set_allocation rect;
      self#compute_allocations

    method add : 'a. ?position : int -> ?expand : bool -> (#t as 'a) -> unit = fun ?position ?(expand = true) widget ->
      let child = {
        widget = (widget :> t);
        expand = expand;
        length = 0;
      } in
      (match position with
        | Some n ->
            children <- insert child children n
        | None ->
            children <- children @ [child]);
      widget#set_parent (Some (self :> t));
      self#compute_size_request;
      self#compute_allocations;
      self#queue_draw

    method remove : 'a. (#t as 'a) -> unit = fun widget ->
      children <- List.filter (fun child -> if child.widget = (widget :> t) then (child.widget#set_parent None; false) else true) children;
      self#compute_size_request;
      self#compute_allocations;
      self#queue_draw
  end

  class hbox = object(self)
    inherit abox "hbox"

    method private compute_size_request =
      size_request <- (
        List.fold_left
          (fun acc child ->
            let size = child.widget#size_request in
            { rows = max acc.rows size.rows; cols = acc.cols + size.cols })
          { rows = 0; cols = 0 }
          children
      )

    method private compute_allocations =
      let rect = self#allocation in
      let cols = rect.col2 - rect.col1 in
      let total_requested_cols = List.fold_left (fun acc child -> acc + child.widget#size_request.cols) 0 children in
      if total_requested_cols <= cols then begin
        (* There is enough space for everybody, we split free space
          between children that can expand. *)
        (* Count the number of children that can expand. *)
        let count_can_expand = List.fold_left (fun acc child -> if child.expand then acc + 1 else acc) 0 children in
        (* Divide free space between these children. *)
        let widthf = if count_can_expand = 0 then 0. else float (cols - total_requested_cols) /. float count_can_expand in
        let rec loop colf = function
          | [] ->
              ()
          | [child] ->
              let width = cols - truncate colf in
              child.length <- width
          | child :: rest ->
              let req_cols = child.widget#size_request.cols in
              if child.expand then begin
                let col = truncate colf in
                let width = req_cols + truncate (colf +. widthf) - col in
                child.length <- width;
                loop (colf +. float req_cols +. widthf) rest
              end else begin
                child.length <- req_cols;
                loop (colf +. float req_cols) rest
              end
        in
        loop 0. children
      end else begin
        (* There is not enough space for everybody. *)
        if total_requested_cols = 0 then
          List.iter (fun child -> child.length <- 0) children
        else
          let rec loop col = function
            | [] ->
                ()
            | [child] ->
                let width = cols - col in
                child.length <- width
            | child :: rest ->
                let width = child.widget#size_request.cols * cols / total_requested_cols in
                child.length <- width;
                loop (col + width) rest
          in
          loop 0 children
      end;
      ignore (
        List.fold_left
          (fun col child ->
            child.widget#set_allocation {
              row1 = rect.row1;
              col1 = col;
              row2 = rect.row2;
              col2 = col + child.length;
            };
            col + child.length)
          rect.col1 children
      )

    method! draw ctx focused =
      let rect = self#allocation in
      let rec loop col children =
        match children with
          | [] ->
              ()
          | child :: rest ->
              child.widget#draw
                (LTerm_draw.sub ctx {
                  row1 = 0;
                  col1 = col;
                  row2 = rect.row2 - rect.row1;
                  col2 = col + child.length;
                })
                focused;
              loop (col + child.length) rest
      in
      loop 0 children
  end

  class vbox = object(self)
    inherit abox "vbox"

    method private compute_size_request =
      size_request <- (
        List.fold_left
          (fun acc child ->
            let size = child.widget#size_request in
            { rows = acc.rows  + size.rows; cols = max acc.cols size.cols })
          { rows = 0; cols = 0 }
          children
      )

    method private compute_allocations =
      let rect = self#allocation in
      let rows = rect.row2 - rect.row1 in
      let total_requested_rows = List.fold_left (fun acc child -> acc + child.widget#size_request.rows) 0 children in
      if total_requested_rows <= rows then begin
        (* There is enough space for everybody, we split free space
          between children that can expand. *)
        (* Count the number of children that can expand. *)
        let count_can_expand = List.fold_left (fun acc child -> if child.expand then acc + 1 else acc) 0 children in
        (* Divide free space between these children. *)
        let heightf = if count_can_expand = 0 then 0. else float (rows - total_requested_rows) /. float count_can_expand in
        let rec loop rowf = function
          | [] ->
              ()
          | [child] ->
              let height = rows - truncate rowf in
              child.length <- height
          | child :: rest ->
              let req_rows = child.widget#size_request.rows in
              if child.expand then begin
                let row = truncate rowf in
                let height = req_rows + truncate (rowf +. heightf) - row in
                child.length <- height;
                loop (rowf +. float req_rows +. heightf) rest
              end else begin
                child.length <- req_rows;
                loop (rowf +. float req_rows) rest
              end
        in
        loop 0. children
      end else begin
        (* There is not enough space for everybody. *)
        if total_requested_rows = 0 then
          List.iter (fun child -> child.length <- 0) children
        else
          let rec loop row = function
            | [] ->
                ()
            | [child] ->
                let height = rows - row in
                child.length <- height
            | child :: rest ->
                let height = child.widget#size_request.rows * rows / total_requested_rows in
                child.length <- height;
                loop (row + height) rest
          in
          loop 0 children
      end;
      ignore (
        List.fold_left
          (fun row child ->
            child.widget#set_allocation {
              row1 = row;
              col1 = rect.col1;
              row2 = row + child.length;
              col2 = rect.col2;
            };
            row + child.length)
          rect.row1 children
      )

    method! draw ctx focused =
      let rect = self#allocation in
      let rec loop row children =
        match children with
          | [] ->
              ()
          | child :: rest ->
              child.widget#draw
                (LTerm_draw.sub ctx {
                  row1 = row;
                  col1 = 0;
                  row2 = row + child.length;
                  col2 = rect.col2 - rect.col1;
                })
                focused;
              loop (row + child.length) rest
      in
      loop 0 children
  end

  class frame = object(self)
    inherit t "frame" as super

    val mutable child = None
    method! children =
      match child with
        | Some widget -> [widget]
        | None -> []

    val mutable size_request = { rows = 2; cols = 2 }
    method! size_request = size_request

    val mutable style = LTerm_style.none
    val mutable connection = LTerm_draw.Light
    method! update_resources =
      let rc = self#resource_class and resources = self#resources in
      style <- LTerm_resources.get_style rc resources;
      connection <- LTerm_resources.get_connection (rc ^ ".connection") resources

    method private compute_size_request =
      match child with
        | Some widget ->
            let size = widget#size_request in
            size_request <- { rows = size.rows + 2; cols = size.cols + 2 }
        | None ->
            size_request <- { rows = 2; cols = 2 }

    method private compute_allocation =
      match child with
        | Some widget ->
            let rect = self#allocation in
            let row1 = min rect.row2 (rect.row1 + 1) and col1 = min rect.col2 (rect.col1 + 1) in
            widget#set_allocation {
              row1 = row1;
              col1 = col1;
              row2 = max row1 (rect.row2 - 1);
              col2 = max col1 (rect.col2 - 1);
            }
        | None ->
            ()

    method! set_allocation rect =
      super#set_allocation rect;
      self#compute_allocation

    method set : 'a. (#t as 'a) -> unit = fun widget ->
      child <- Some(widget :> t);
      widget#set_parent (Some (self :> t));
      self#compute_size_request;
      self#compute_allocation;
      self#queue_draw

    method empty =
      match child with
        | Some widget ->
            widget#set_parent None;
            child <- None;
            self#compute_size_request;
            self#queue_draw
        | None ->
            ()
    val mutable label = Zed_string.empty ()
    val mutable align = H_align_left
    method set_label ?(alignment=H_align_left) l =
      label <- LiteralIntf.to_string_exn l;
      align <- alignment

    method! draw ctx focused =
      let size = LTerm_draw.size ctx in
      LTerm_draw.fill_style ctx style;
      if size.rows >= 1 && size.cols >= 1 then begin
        let rect =
          { row1 = 0;
            col1 = 0;
            row2 = size.rows;
            col2 = size.cols }
        in
        (if Zed_string.bytes label = 0 then LTerm_draw.draw_frame ctx rect connection
        else LTerm_draw.draw_frame_labelled ctx rect ~alignment:align label connection);
        if size.rows > 2 && size.cols > 2 then
          match child with
            | Some widget ->
                widget#draw
                  (LTerm_draw.sub ctx { row1 = 1;
                            col1 = 1;
                            row2 = size.rows - 1;
                            col2 = size.cols - 1 })
                  focused
            | None ->
                ()
      end
  end

  class modal_frame = object(self)
    inherit frame

    val mutable work_area = None

    method! private compute_allocation =
      match child with
      | Some widget ->
        (* The desired layout is as following:
        *
        *  ..............................
        *  .                            .
        *  .    ---------------------   .
        *  .    ||                 ||   .
        *  .    || child widget is ||   .
        *  .    ||    centered     ||   .
        *  .    ||                 ||   .
        *  .    ---------------------   .
        *  .                            .
        *  ..............................
        *)
          let rect = self#allocation in
          (* First find out how much space we have *)
          let alloc_height = rect.row2 - rect.row1 in
          let alloc_width = rect.col2 - rect.col1 in
          (* Then how much child widget wants *)
          let request = widget#size_request in
          (* Now we calculate how big margins could be, taking into account:
          * - for vertical margin two lines of the frame and two empty lines
          * between it and the child widget
          * - for horizontal margin four lines of the frame and two empty lines
          * between it and the child widget *)
          let margin_height = max 0 (alloc_height - request.rows - 4) / 2 in
          let margin_width = max 0 (alloc_width - request.cols - 6) / 2 in
          (* the child widget would like to be here (again taking into account
          * frame lines and emty lines between frame and the child widget *)
          let desired_row1 = rect.row1 + margin_height + 2 in
          let desired_row2 = desired_row1 + request.rows in
          let desired_col1 = rect.col1 + margin_width + 3 in
          let desired_col2 = desired_col1 + request.cols in
          (* make sure we stay inside the modal_frame *)
          (* Remember that right and left margins for the widget inside the frame
          * are 3, and top and bottom margins are 2 *)
          let row1 = min desired_row1 (rect.row2 - 2) in
          let row2 = min desired_row2 (rect.row2 - 2) in
          let col1 = min desired_col1 (rect.col2 - 3) in
          let col2 = min desired_col2 (rect.col2 - 3) in
          (* now inform the child widget about its area *)
          widget#set_allocation {
            row1 = row1;
            col1 = col1;
            row2 = row2;
            col2 = col2;
          };
          (* modal_frame is not going to touch anything outside of the child
          * widget and frame around *)
          work_area <- Some { row1 = max rect.row1 (row1 - 2);
                              row2 = min rect.row2 (row2 + 2);
                              col1 = max rect.col1 (col1 - 3);
                              col2 = min rect.col2 (col2 + 3) };
      | None ->
          ()

    method! draw ctx focused =
      match work_area with
      | None -> ()
      | Some area ->
          let work_ctx = LTerm_draw.sub ctx area in
          (* modal_frame is drawing only inside centered area (the child widget
          * and frame around) so create appropriate drawing context *)
          let size = LTerm_draw.size work_ctx in
          if size.rows >= 1 && size.cols >= 1 then begin
            LTerm_draw.fill_style work_ctx style;
            LTerm_draw.clear work_ctx;
            let width = area.col2 - area.col1 in
            let height = area.row2 - area.row1 in
            (* outer part of the frame *)
            LTerm_draw.draw_frame
              work_ctx
              { row1 = 0;
                col1 = 0;
                row2 = height;
                col2 = width }
              connection;
            (* inner part of the frame *)
            LTerm_draw.draw_frame
              work_ctx
              { row1 = 0;
                col1 = 1;
                row2 = height;
                col2 = width - 1 }
              connection;
            if size.rows > 4 && size.cols > 6 then
              match child with
              | Some widget ->
                  (* decorations around the child widget take 4 columns and 6
                  * rows *)
                  let widget_ctx = LTerm_draw.sub work_ctx { row1 = 2;
                                                            row2 = height - 2;
                                                            col1 = 3;
                                                            col2 = width - 3} in
                  widget#draw widget_ctx focused
              | None ->
                  ()
          end

    initializer
      self#set_resource_class "modal_frame"

  end
end
