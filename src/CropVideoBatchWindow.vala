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

public class CropVideoBatchWindow : Gtk.Dialog {
	private Gtk.Box vboxMain;
	private Gtk.TreeView tvFiles;
	private Gtk.ScrolledWindow swFiles;
	
	private Gtk.TreeViewColumn colCropL;
	private Gtk.TreeViewColumn colCropR;
	private Gtk.TreeViewColumn colCropT;
	private Gtk.TreeViewColumn colCropB;
	private Gtk.TreeViewColumn colStartPos;
	private Gtk.TreeViewColumn colEndPos;
	private Gtk.TreeViewColumn colEdit;

	private MediaFile SelectedFile = null;

	private Gtk.Button btnOk;

	private string action = "";
	
	public static Gtk.Window CropVideos(Gtk.Window parent){
		var win = new CropVideoBatchWindow(parent, "crop");
		parent.hide();
		return win;
	}

	public static Gtk.Window TrimFiles(Gtk.Window parent){
		var win = new CropVideoBatchWindow(parent, "trim");
		parent.hide();
		return win;
	}
	
	public CropVideoBatchWindow(Gtk.Window? parent, string _action) {
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
		vboxMain = get_content_area();
		vboxMain.set_size_request(600,500);

		init_ui_file_list();

		// btnOk
        btnOk = (Button) add_button ("gtk-ok", Gtk.ResponseType.ACCEPT);
        btnOk.clicked.connect (btnOk_clicked);
        
        refresh_list_view();

        this.destroy.connect(()=>{ parent.show(); });

        show_all();
	}

	private void init_ui_file_list(){
		//tvFiles
		tvFiles = new TreeView();
		tvFiles.get_selection().mode = SelectionMode.MULTIPLE;
		//tvFiles.set_tooltip_text (_("Right-click for more options"));
		tvFiles.headers_clickable = true;
		tvFiles.activate_on_single_click = true;
		tvFiles.rules_hint = true;
		
		swFiles = new ScrolledWindow(tvFiles.get_hadjustment(), tvFiles.get_vadjustment());
		swFiles.set_shadow_type (ShadowType.ETCHED_IN);
		swFiles.add (tvFiles);
		swFiles.margin = 3;
		swFiles.set_size_request (-1, 150);
		vboxMain.pack_start (swFiles, true, true, 0);
	
		CellRendererText cellText;
		CellRendererSpin cellSpin;

		//colName
		var colName = new TreeViewColumn();
		colName.title = _("File");
		colName.expand = true;
		colName.resizable = true;
		colName.clickable = true;
		colName.min_width = 100;
		tvFiles.append_column(colName);
		
		cellText = new CellRendererText();
		cellText.xalign = (float) 0.0;
		cellText.ellipsize = Pango.EllipsizeMode.END;
		colName.pack_start (cellText, false);
		colName.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			MediaFile mf;
			model.get (iter, 0, out mf, -1);
			(cell as Gtk.CellRendererText).text = mf.Name;
		});

		
		//colCropL
		colCropL = new TreeViewColumn();
		colCropL.title = _("Crop Left");
		colCropL.fixed_width = 80;
		tvFiles.append_column(colCropL);
		
		cellSpin = new CellRendererSpin();
		//cellSpin.xalign = (float) 0.5;
		cellSpin.editable = true;
		cellSpin.adjustment = new Gtk.Adjustment (0, 0, 2000, 1, 2, 0);
		cellSpin.edited.connect ((path, new_text) => {
			colCrop_cell_edited(path, new_text, TreeColumn.CROP_LEFT);
		});
		
		colCropL.pack_start (cellSpin, false);
		colCropL.set_attributes(cellSpin, "text",  TreeColumn.CROP_LEFT);

		//colCropR
		colCropR = new TreeViewColumn();
		colCropR.title = _("Right");
		colCropR.fixed_width = 80;
		tvFiles.append_column(colCropR);
		
		cellSpin = new CellRendererSpin();
		//cellSpin.xalign = (float) 0.5;
		cellSpin.editable = true;
		cellSpin.adjustment = new Gtk.Adjustment (0, 0, 2000, 1, 2, 0);
		cellSpin.edited.connect ((path, new_text) => {
			colCrop_cell_edited(path, new_text, TreeColumn.CROP_RIGHT);
		});
		
		colCropR.pack_start (cellSpin, false);
		colCropR.set_attributes(cellSpin, "text", TreeColumn.CROP_RIGHT);

		//colCropT
		colCropT = new TreeViewColumn();
		colCropT.title = _("Top");
		colCropT.fixed_width = 80;
		tvFiles.append_column(colCropT);
		
		cellSpin = new CellRendererSpin();
		//cellSpin.xalign = (float) 0.5;
		cellSpin.editable = true;
		cellSpin.adjustment = new Gtk.Adjustment (0, 0, 2000, 1, 2, 0);
		cellSpin.edited.connect ((path, new_text) => {
			colCrop_cell_edited(path, new_text, TreeColumn.CROP_TOP);
		});
		
		colCropT.pack_start (cellSpin, false);
		colCropT.set_attributes(cellSpin, "text", TreeColumn.CROP_TOP);

		//colCropB
		colCropB = new TreeViewColumn();
		colCropB.title = _("Bottom");
		colCropB.fixed_width = 80;
		tvFiles.append_column(colCropB);
		
		cellSpin = new CellRendererSpin();
		//cellSpin.xalign = (float) 0.5;
		cellSpin.editable = true;
		cellSpin.adjustment = new Gtk.Adjustment (0, 0, 2000, 1, 2, 0);
		cellSpin.edited.connect ((path, new_text) => {
			colCrop_cell_edited(path, new_text, TreeColumn.CROP_BOTTOM);
		});
		
		colCropB.pack_start (cellSpin, false);
		colCropB.set_attributes(cellSpin, "text", TreeColumn.CROP_BOTTOM);

		//colStartPos --------------------------------------------
		
		colStartPos = new TreeViewColumn();
		colStartPos.title = _("StartPos");
		colStartPos.fixed_width = 80;
		tvFiles.append_column(colStartPos);
		
		cellSpin = new CellRendererSpin();
		//cellSpin.xalign = (float) 0.5;
		cellSpin.editable = true;
		cellSpin.digits = 1;
		cellSpin.adjustment = new Gtk.Adjustment (0, 0, 2000, 1, 2, 0);
		cellSpin.edited.connect ((path, new_text) => {
			colCrop_cell_edited(path, new_text, TreeColumn.START_POS);
		});
		
		colStartPos.pack_start (cellSpin, false);
		colStartPos.set_attributes(cellSpin, "text", TreeColumn.START_POS);

		//colEndPos ----------------------------------------------
		
		colEndPos = new TreeViewColumn();
		colEndPos.title = _("EndPos");
		colEndPos.fixed_width = 80;
		tvFiles.append_column(colEndPos);
		
		cellSpin = new CellRendererSpin();
		//cellSpin.xalign = (float) 0.5;
		cellSpin.editable = true;
		cellSpin.digits = 1;
		cellSpin.adjustment = new Gtk.Adjustment (0, 0, 2000, 1, 2, 0);
		cellSpin.edited.connect ((path, new_text) => {
			colCrop_cell_edited(path, new_text, TreeColumn.END_POS);
		});
		
		colEndPos.pack_start (cellSpin, false);
		colEndPos.set_attributes(cellSpin, "text", TreeColumn.END_POS);

		//colEdit
		var pixbuf = new Gtk.CellRendererPixbuf();
		pixbuf.icon_name = "gtk-edit";
		colEdit = new Gtk.TreeViewColumn();
		colEdit.title = _("Edit");
		colEdit.pack_start (pixbuf, false);
		tvFiles.append_column(colEdit);

		//colSpacer
		var colSpacer = new TreeViewColumn();
		colSpacer.expand = false;
		colSpacer.fixed_width = 10;
		tvFiles.append_column(colSpacer);
		
		tvFiles.row_activated.connect((path, column)=>{
			var store = (Gtk.ListStore) tvFiles.model;
			MediaFile mf;
			TreeIter iter;
			store.get_iter_from_string (out iter, path.to_string());
			store.get (iter, 0, out mf, -1);

			SelectedFile = mf;
		
			if (column == colEdit){
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
		var model = (Gtk.ListStore) tvFiles.model;
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

		tvFiles.set_model (store);
		
		tvFiles.columns_autosize();

		if (action == "crop"){
			colCropL.visible = true;
			colCropR.visible = true;
			colCropT.visible = true;
			colCropB.visible = true;
			colStartPos.visible = false;
			colEndPos.visible = false;
		}
		else if (action == "trim"){
			colCropL.visible = false;
			colCropR.visible = false;
			colCropT.visible = false;
			colCropB.visible = false;
			colStartPos.visible = true;
			colEndPos.visible = true;
		}
	}


	private void btnOk_clicked(){
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


