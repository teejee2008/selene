/*
 * SimpleProgressWindow.vala
 *
 * Copyright 2015 Tony George <teejee2008@gmail.com>
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

public class ColumnSelectionDialog : Gtk.Dialog {

	private Gtk.TreeView tvCols;
	
	public ColumnSelectionDialog.with_parent(Window parent, Gee.HashMap<TreeViewColumn,TreeViewListColumn> col_list) {
		title = _("Select Columns");
		
		set_transient_for(parent);
		set_modal(true);
		set_skip_taskbar_hint(true);
		set_skip_pager_hint(true);
		window_position = WindowPosition.CENTER_ON_PARENT;
		deletable = false;
		resizable = false;
		
		set_transient_for(parent);
		set_modal(true);

		// get content area
		var vboxMain = get_content_area();
		vboxMain.set_size_request(300,300);

		//add treeview for columns
		tvCols = new TreeView();
		tvCols.get_selection().mode = SelectionMode.MULTIPLE;
		tvCols.set_tooltip_text (_("Drag and drop to re-order"));
		tvCols.headers_visible = false;
		tvCols.reorderable = true;

		var swCols = new ScrolledWindow(tvCols.get_hadjustment(), tvCols.get_vadjustment());
		swCols.set_shadow_type (ShadowType.ETCHED_IN);
		swCols.add (tvCols);
		swCols.margin = 6;
		vboxMain.pack_start (swCols, true, true, 0);
	
		CellRendererText cellText;
		
		//colName
		var colName = new TreeViewColumn();
		colName.title = _("File");
		colName.expand = true;
		tvCols.append_column(colName);

		//cell toggle
		CellRendererToggle cell_select = new CellRendererToggle ();
		cell_select.activatable = true;
		colName.pack_start (cell_select, false);
		colName.set_cell_data_func (cell_select, (cell_layout, cell, model, iter) => {
			bool selected;
			TreeViewListColumn col;
			model.get (iter, 0, out selected, 1, out col, -1);
			(cell as Gtk.CellRendererToggle).active = selected;
		});

		cell_select.toggled.connect((path) => {
			var store = (Gtk.ListStore) tvCols.model;
			bool selected;
			TreeViewListColumn col;

			TreeIter iter;
			store.get_iter_from_string (out iter, path);
			store.get (iter, 0, out selected, 1, out col, -1);

			col.Selected = !selected;

			store.set(iter, 0, col.Selected, -1);
		});

		//cell text
		cellText = new CellRendererText();
		cellText.ellipsize = Pango.EllipsizeMode.END;
		colName.pack_start (cellText, false);
		colName.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			TreeViewListColumn col;
			model.get (iter, 1, out col, -1);
			(cell as Gtk.CellRendererText).text = col.FullDisplayName;
		});

		//create sorted list ---------------------
		
		TreeIter iter;
		var lst_all = new Gee.ArrayList<TreeViewListColumn>();
		foreach(TreeViewListColumn col in col_list.values){
			lst_all.add(col);
		}
		CompareDataFunc<TreeViewListColumn> func = (a, b) => {
			return strcmp(a.FullDisplayName,b.FullDisplayName);
		};
		lst_all.sort((owned)func);

		//created ordered list --------------------
		
		var lst = new Gee.ArrayList<TreeViewListColumn>();
		//add selected columns in order
		foreach(string col_name in App.ListViewColumns.split(",")){
			foreach(TreeViewListColumn col in col_list.values){
				if (col.Name == col_name){
					lst.add(col);
					break;
				}
			}
		}
		//add unselected
		foreach(TreeViewListColumn col in lst_all){
			if (!col.Selected){
				lst.add(col);
			}
		}
		
		//add rows ----------------------
		
		var store = new Gtk.ListStore (2, typeof(bool), typeof(TreeViewListColumn));
		foreach(TreeViewListColumn col in lst){
			store.append (out iter);
			store.set (iter, 0, col.Selected);
			store.set (iter, 1, col);
		}
		tvCols.model = store;

		// btnSave
        var btnSave = (Button) add_button ("gtk-save", Gtk.ResponseType.ACCEPT);
        btnSave.clicked.connect (()=>{
			save_columns(col_list);
			this.close();
		});

        // btnCancel
        var btnCancel = (Button) add_button ("gtk-cancel", Gtk.ResponseType.CANCEL);
        btnCancel.clicked.connect (()=>{
			this.close();
		});
		
        show_all();
	}

	private void save_columns(Gee.HashMap<TreeViewColumn,TreeViewListColumn> col_list){
		if (col_list == null){
			return;
		}

		string s = "";

		//get ordered list -----------------------
		
		var list = new Gee.ArrayList<TreeViewListColumn>();

		TreeIter iter;
		bool iterExists = tvCols.model.get_iter_first (out iter);
		while (iterExists) {
			TreeViewListColumn item;
			tvCols.model.get (iter, 1, out item, -1);
			list.add(item);
			iterExists = tvCols.model.iter_next (ref iter);
		}

		// create string of column names -------------
		
		foreach(TreeViewListColumn col in list){
			if (col.Selected){
				s += col.Name + ",";
			}
		}
		if (s.has_suffix(",")){
			s = s[0:s.length - 1];
		}

		App.ListViewColumns = s;
	}
}


