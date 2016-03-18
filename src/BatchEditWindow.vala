/*
 * CropVideoBatchWindow.vala
 *
 * Copyright 2012 Tony George <teejee2008@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */

using Gtk;
using Gee;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

public class BatchEditWindow : Gtk.Dialog {
	private Gtk.Box vbox_main;
	private Gtk.TreeView tv_files;
	private Gtk.ScrolledWindow sw_files;
	
	private Gtk.TreeViewColumn col_crop_l;
	private Gtk.TreeViewColumn col_crop_r;
	private Gtk.TreeViewColumn col_crop_t;
	private Gtk.TreeViewColumn col_crop_b;
	private Gtk.TreeViewColumn col_start_pos;
	private Gtk.TreeViewColumn col_end_pos;
	private Gtk.TreeViewColumn col_edit;

	private MediaFile SelectedFile = null;

	private Gtk.Button btn_crop_auto;
	private Gtk.Button btn_crop_reset;
	private Gtk.Button btn_ok;

	private string action = "";
	private bool crop_detect_is_running = false;
	
	public static Gtk.Window CropVideos(Gtk.Window parent){
		var win = new BatchEditWindow(parent, "crop");
		parent.hide();
		return win;
	}

	public static Gtk.Window TrimFiles(Gtk.Window parent){
		var win = new BatchEditWindow(parent, "trim");
		parent.hide();
		return win;
	}
	
	public BatchEditWindow(Gtk.Window? parent, string _action) {
		set_transient_for(parent);
		set_destroy_with_parent(true);
        //set_skip_taskbar_hint(true);

		window_position = WindowPosition.CENTER_ON_PARENT;
		icon = get_app_icon(16);
		
		modal = true;
		deletable = true;
		resizable = true;

		action = _action;

		if (action == "crop"){
			title = "Crop Videos (Batch)";
		}
		else if (action == "trim"){
			title = "Trim Duration (Batch)";
		}
		
		// get content area
		vbox_main = get_content_area();
		vbox_main.set_size_request(600,500);

		init_ui_file_list();

		if (action == "crop"){
			// btn_crop_auto
			btn_crop_auto = (Button) add_button ("Auto Crop", Gtk.ResponseType.NONE);
			btn_crop_auto.clicked.connect(btn_crop_auto_clicked);

			// btn_crop_reset
			btn_crop_reset = (Button) add_button ("Reset", Gtk.ResponseType.NONE);
			btn_crop_reset.clicked.connect (btn_crop_reset_clicked);
		}

		// btn_ok
        btn_ok = (Button) add_button ("gtk-ok", Gtk.ResponseType.ACCEPT);
        btn_ok.clicked.connect (btn_ok_clicked);
        
        refresh_list_view();

        this.destroy.connect(()=>{ parent.show(); });

        show_all();
	}

	private void init_ui_file_list(){
		//tv_files
		tv_files = new TreeView();
		tv_files.get_selection().mode = SelectionMode.MULTIPLE;
		//tv_files.set_tooltip_text (_("Right-click for more options"));
		tv_files.headers_clickable = true;
		tv_files.activate_on_single_click = true;
		tv_files.rules_hint = true;
		
		sw_files = new ScrolledWindow(tv_files.get_hadjustment(), tv_files.get_vadjustment());
		sw_files.set_shadow_type (ShadowType.ETCHED_IN);
		sw_files.add (tv_files);
		sw_files.margin = 3;
		sw_files.set_size_request (-1, 150);
		vbox_main.pack_start (sw_files, true, true, 0);
	
		CellRendererText cellText;
		CellRendererSpin cellSpin;

		// file name -----------------------------
		
		var col = new TreeViewColumn();
		col.title = _("File");
		col.expand = true;
		col.resizable = true;
		col.clickable = true;
		col.min_width = 100;
		tv_files.append_column(col);
		
		cellText = new CellRendererText();
		cellText.xalign = (float) 0.0;
		cellText.ellipsize = Pango.EllipsizeMode.END;
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			model.get (iter, 0, out mf, -1);
			(cell as Gtk.CellRendererText).text = mf.Name;
		});

		
		// crop left -------------------------------------------
		
		col = new TreeViewColumn();
		col.title = _("Crop Left");
		col.fixed_width = 80;
		tv_files.append_column(col);
		col_crop_l = col;
		
		cellSpin = new CellRendererSpin();
		//cellSpin.xalign = (float) 0.5;
		cellSpin.editable = true;
		cellSpin.adjustment = new Gtk.Adjustment (0, 0, 2000, 1, 2, 0);
		cellSpin.edited.connect ((path, new_text) => {
			colCrop_cell_edited(path, new_text, TreeColumn.CROP_LEFT);
		});
		
		col.pack_start (cellSpin, false);
		col.set_attributes(cellSpin, "text",  TreeColumn.CROP_LEFT);

		// crop right -------------------------------------------
		
		//col_crop_r
		col = new TreeViewColumn();
		col.title = _("Right");
		col.fixed_width = 80;
		tv_files.append_column(col);
		col_crop_r = col;
		
		cellSpin = new CellRendererSpin();
		//cellSpin.xalign = (float) 0.5;
		cellSpin.editable = true;
		cellSpin.adjustment = new Gtk.Adjustment (0, 0, 2000, 1, 2, 0);
		cellSpin.edited.connect ((path, new_text) => {
			colCrop_cell_edited(path, new_text, TreeColumn.CROP_RIGHT);
		});
		
		col.pack_start (cellSpin, false);
		col.set_attributes(cellSpin, "text", TreeColumn.CROP_RIGHT);

		// crop top -------------------------------------------
		
		//col_crop_t
		col = new TreeViewColumn();
		col.title = _("Top");
		col.fixed_width = 80;
		tv_files.append_column(col);
		col_crop_t = col;
		
		cellSpin = new CellRendererSpin();
		//cellSpin.xalign = (float) 0.5;
		cellSpin.editable = true;
		cellSpin.adjustment = new Gtk.Adjustment (0, 0, 2000, 1, 2, 0);
		cellSpin.edited.connect ((path, new_text) => {
			colCrop_cell_edited(path, new_text, TreeColumn.CROP_TOP);
		});
		
		col.pack_start (cellSpin, false);
		col.set_attributes(cellSpin, "text", TreeColumn.CROP_TOP);

		// crop bottom -------------------------------------------
		
		//col_crop_b
		col = new TreeViewColumn();
		col.title = _("Bottom");
		col.fixed_width = 80;
		tv_files.append_column(col);
		col_crop_b = col;
		
		cellSpin = new CellRendererSpin();
		//cellSpin.xalign = (float) 0.5;
		cellSpin.editable = true;
		cellSpin.adjustment = new Gtk.Adjustment (0, 0, 2000, 1, 2, 0);
		cellSpin.edited.connect ((path, new_text) => {
			colCrop_cell_edited(path, new_text, TreeColumn.CROP_BOTTOM);
		});
		
		col.pack_start (cellSpin, false);
		col.set_attributes(cellSpin, "text", TreeColumn.CROP_BOTTOM);

		// start pos --------------------------------------------

		//col_start_pos
		col = new TreeViewColumn();
		col.title = _("StartPos");
		col.fixed_width = 80;
		tv_files.append_column(col);
		col_start_pos = col;
		
		cellSpin = new CellRendererSpin();
		//cellSpin.xalign = (float) 0.5;
		cellSpin.editable = true;
		cellSpin.digits = 1;
		cellSpin.adjustment = new Gtk.Adjustment (0, 0, 2000, 1, 2, 0);
		cellSpin.edited.connect ((path, new_text) => {
			colCrop_cell_edited(path, new_text, TreeColumn.START_POS);
		});
		
		col.pack_start (cellSpin, false);
		col.set_attributes(cellSpin, "text", TreeColumn.START_POS);

		// end pos --------------------------------------------
			
		//col_end_pos
		col = new TreeViewColumn();
		col.title = _("EndPos");
		col.fixed_width = 80;
		tv_files.append_column(col);
		col_end_pos = col;
		
		cellSpin = new CellRendererSpin();
		//cellSpin.xalign = (float) 0.5;
		cellSpin.editable = true;
		cellSpin.digits = 1;
		cellSpin.adjustment = new Gtk.Adjustment (0, 0, 2000, 1, 2, 0);
		cellSpin.edited.connect ((path, new_text) => {
			colCrop_cell_edited(path, new_text, TreeColumn.END_POS);
		});
		
		col.pack_start (cellSpin, false);
		col.set_attributes(cellSpin, "text", TreeColumn.END_POS);

		// edit -----------------------------------------
		
		//col_edit
		col = new Gtk.TreeViewColumn();
		col.title = _("Edit");
		tv_files.append_column(col);
		col_edit = col;

		var pixbuf = new Gtk.CellRendererPixbuf();
		pixbuf.icon_name = "gtk-edit";
		col.pack_start (pixbuf, false);
		
		// spacer -------------------------------
		
		col = new TreeViewColumn();
		col.expand = false;
		col.fixed_width = 10;
		tv_files.append_column(col);

		// handlers ------------------------------
		
		tv_files.row_activated.connect((path, column)=>{
			var store = (Gtk.ListStore) tv_files.model;
			MediaFile mf;
			TreeIter iter;
			store.get_iter_from_string (out iter, path.to_string());
			store.get (iter, 0, out mf, -1);

			SelectedFile = mf;
		
			if (column == col_edit){
				if (action == "crop"){
					var win = MediaPlayerWindow.CropVideo(mf, this);
					win.destroy.connect(()=>{
						store.set(iter, TreeColumn.CROP_LEFT, mf.CropL.to_string());
						store.set(iter, TreeColumn.CROP_RIGHT, mf.CropR.to_string());
						store.set(iter, TreeColumn.CROP_TOP, mf.CropT.to_string());
						store.set(iter, TreeColumn.CROP_BOTTOM, mf.CropB.to_string());
					});
				}
				else if (action == "trim"){
					var win = MediaPlayerWindow.TrimFile(mf, this);
					win.destroy.connect(()=>{
						store.set(iter, TreeColumn.START_POS, "%.1f".printf(mf.StartPos));
						store.set(iter, TreeColumn.END_POS, "%.1f".printf(mf.EndPos));
					});
				}
			}
		});
	}

	private void colCrop_cell_edited(string path, string new_text, TreeColumn field){
		TreeIter iter;
		var model = (Gtk.ListStore) tv_files.model;
		MediaFile mf = null;
		if (model.get_iter_from_string (out iter, path)){
			model.get (iter, 0, out mf, -1);
		}
		else{
			return;
		}

		switch (field){
			case TreeColumn.CROP_LEFT:
				mf.CropL = int.parse(new_text);
				break;
			case TreeColumn.CROP_RIGHT:
				mf.CropR = int.parse(new_text);
				break;
			case TreeColumn.CROP_TOP:
				mf.CropT = int.parse(new_text);
				break;
			case TreeColumn.CROP_BOTTOM:
				mf.CropB = int.parse(new_text);
				break;
			case TreeColumn.START_POS:
				mf.StartPos = double.parse(new_text);
				break;
			case TreeColumn.END_POS:
				mf.EndPos = double.parse(new_text);
				break;
		}

		model.set (iter, field, (new_text == "0") ? "" : new_text);
	}  
	
	private void refresh_list_view (){
		var store = new Gtk.ListStore (7,  
				typeof(MediaFile), 	//FILE_REF
				typeof(string), 	//CROP_LEFT
				typeof(string), 	//CROP_RIGHT
				typeof(string), 	//CROP_TOP
				typeof(string), 	//CROP_BOTTOM
				typeof(string),		//START_POS
				typeof(string) 		//END_POS
				);

		TreeIter iter;
		foreach(MediaFile mf in App.InputFiles) {

			if (action == "crop"){
				if (!mf.HasVideo){
					continue;
				}
			}
			
			store.append (out iter);
			store.set(iter, TreeColumn.FILE_REF, mf);
			store.set(iter, TreeColumn.CROP_LEFT, mf.CropL.to_string());
			store.set(iter, TreeColumn.CROP_RIGHT, mf.CropR.to_string());
			store.set(iter, TreeColumn.CROP_TOP, mf.CropT.to_string());
			store.set(iter, TreeColumn.CROP_BOTTOM, mf.CropB.to_string());
			store.set(iter, TreeColumn.START_POS, "%.1f".printf(mf.StartPos));
			store.set(iter, TreeColumn.END_POS, "%.1f".printf(mf.EndPos));
		}

		tv_files.set_model (store);
		
		tv_files.columns_autosize();

		if (action == "crop"){
			col_crop_l.visible = true;
			col_crop_r.visible = true;
			col_crop_t.visible = true;
			col_crop_b.visible = true;
			col_start_pos.visible = false;
			col_end_pos.visible = false;
		}
		else if (action == "trim"){
			col_crop_l.visible = false;
			col_crop_r.visible = false;
			col_crop_t.visible = false;
			col_crop_b.visible = false;
			col_start_pos.visible = true;
			col_end_pos.visible = true;
		}
	}

	private void btn_crop_auto_clicked(){
		TreeSelection selection = tv_files.get_selection();
		if (selection.count_selected_rows() == 0){
			string title = _("No Files Selected");
			string msg = _("Select some files from the list");
			gtk_messagebox(title,msg,this,true);
			return;
		}

		var status_msg = _("Detecting borders...");
		var dlg = new SimpleProgressWindow.with_parent(this, status_msg);
		dlg.set_title(status_msg);
		dlg.show_all();
		gtk_do_events();
		
		TreeModel model;
		GLib.List<TreePath> lst = selection.get_selected_rows (out model);

		App.progress_total = (int) lst.length();
		App.progress_count = 0;
		
		for(int k=0; k<lst.length(); k++){
			TreePath path = lst.nth_data (k);
			TreeIter iter;
			model.get_iter (out iter, path);
			MediaFile mf;
			model.get (iter, 0, out mf, -1);

			SelectedFile = mf;

			try {
				crop_detect_is_running = true;
				Thread.create<void> (ffmpeg_crop_detect_thread, true);
			} catch (ThreadError e) {
				crop_detect_is_running = false;
				log_error (e.message);
			}

			//dlg.pulse_start();
			dlg.update_message("File: %s".printf(mf.Name));
			while (crop_detect_is_running) {
				dlg.update_progressbar();
				dlg.sleep(200);
				gtk_do_events();
			}
			App.progress_count++;

			var store = (Gtk.ListStore) model;
			store.set(iter, TreeColumn.CROP_LEFT, mf.CropL.to_string());
			store.set(iter, TreeColumn.CROP_RIGHT, mf.CropR.to_string());
			store.set(iter, TreeColumn.CROP_TOP, mf.CropT.to_string());
			store.set(iter, TreeColumn.CROP_BOTTOM, mf.CropB.to_string());

			gtk_do_events();
		}

		dlg.destroy();
	}

	private void ffmpeg_crop_detect_thread() {
		SelectedFile.crop_detect();
		crop_detect_is_running = false;
	}

	private void btn_crop_reset_clicked(){
		TreeSelection selection = tv_files.get_selection();
		if (selection.count_selected_rows() == 0){
			string title = _("No Files Selected");
			string msg = _("Select some files from the list");
			gtk_messagebox(title,msg,this,true);
			return;
		}

		TreeModel model;
		GLib.List<TreePath> lst = selection.get_selected_rows (out model);

		for(int k=0; k<lst.length(); k++){
			TreePath path = lst.nth_data (k);
			TreeIter iter;
			model.get_iter (out iter, path);
			MediaFile mf;
			model.get (iter, 0, out mf, -1);
			mf.CropL = mf.CropR = mf.CropT = mf.CropB = 0;

			var store = (Gtk.ListStore) model;
			store.set(iter, TreeColumn.CROP_LEFT, mf.CropL.to_string());
			store.set(iter, TreeColumn.CROP_RIGHT, mf.CropR.to_string());
			store.set(iter, TreeColumn.CROP_TOP, mf.CropT.to_string());
			store.set(iter, TreeColumn.CROP_BOTTOM, mf.CropB.to_string());
		}
	}
	
	private void btn_ok_clicked(){
		destroy();
	}

	private enum TreeColumn{
		FILE_REF,
		CROP_LEFT,
		CROP_RIGHT,
		CROP_TOP,
		CROP_BOTTOM,
		START_POS,
		END_POS
	}
}


