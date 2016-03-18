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

	private Gtk.TreeView tv_cols;
	
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
		var vbox_main = get_content_area();
		vbox_main.set_size_request(300,300);

		//add treeview for columns
		tv_cols = new TreeView();
		tv_cols.get_selection().mode = SelectionMode.MULTIPLE;
		tv_cols.set_tooltip_text (_("Drag and drop to re-order"));
		tv_cols.headers_visible = false;
		tv_cols.reorderable = true;

		var sw_cols = new ScrolledWindow(tv_cols.get_hadjustment(), tv_cols.get_vadjustment());
		sw_cols.set_shadow_type (ShadowType.ETCHED_IN);
		sw_cols.add (tv_cols);
		sw_cols.margin = 3;
		vbox_main.pack_start (sw_cols, true, true, 0);
	
		//colName
		var col = new TreeViewColumn();
		col.title = _("File");
		col.expand = true;
		tv_cols.append_column(col);

		//cell toggle
		var cell_select = new CellRendererToggle ();
		cell_select.activatable = true;
		col.pack_start (cell_select, false);
		col.set_cell_data_func (cell_select, (cell_layout, cell, model, iter) => {
			bool selected;
			model.get (iter, 0, out selected, -1);
			(cell as Gtk.CellRendererToggle).active = selected;
		});

		cell_select.toggled.connect((path) => {
			var store = (Gtk.ListStore) tv_cols.model;
			bool selected;
			TreeViewListColumn column;

			TreeIter iter;
			store.get_iter_from_string (out iter, path);
			store.get (iter, 0, out selected, 1, out column, -1);

			column.Selected = !selected;

			store.set(iter, 0, column.Selected, -1);
		});

		//cell text
		var cellText = new CellRendererText();
		cellText.ellipsize = Pango.EllipsizeMode.END;
		col.pack_start (cellText, false);
		col.set_cell_data_func (cellText, (cell_layout, cell, model, iter)=>{
			TreeViewListColumn column;
			model.get (iter, 1, out column, -1);
			(cell as Gtk.CellRendererText).text = column.FullDisplayName;
		});

		//create sorted list ---------------------
		
		TreeIter iter;
		var lst_all = new Gee.ArrayList<TreeViewListColumn>();
		foreach(TreeViewListColumn column in col_list.values){
			lst_all.add(column);
		}
		CompareDataFunc<TreeViewListColumn> func = (a, b) => {
			return strcmp(a.FullDisplayName,b.FullDisplayName);
		};
		lst_all.sort((owned)func);

		//created ordered list --------------------
		
		var lst = new Gee.ArrayList<TreeViewListColumn>();
		//add selected columns in order
		foreach(string col_name in App.ListViewColumns.split(",")){
			foreach(TreeViewListColumn column in col_list.values){
				if (column.Name == col_name){
					lst.add(column);
					break;
				}
			}
		}
		//add unselected
		foreach(TreeViewListColumn column in lst_all){
			if (!column.Selected){
				lst.add(column);
			}
		}
		
		//add rows ----------------------
		
		var store = new Gtk.ListStore (2, typeof(bool), typeof(TreeViewListColumn));
		foreach(TreeViewListColumn column in lst){
			store.append (out iter);
			store.set (iter, 0, column.Selected);
			store.set (iter, 1, column);
		}
		tv_cols.model = store;

		// btn_save
        var btn_save = (Button) add_button ("gtk-save", Gtk.ResponseType.ACCEPT);
        btn_save.clicked.connect (()=>{
			save_columns(col_list);
			this.close();
		});

        // btn_cancel
        var btn_cancel = (Button) add_button ("gtk-cancel", Gtk.ResponseType.CANCEL);
        btn_cancel.clicked.connect (()=>{
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
		bool iterExists = tv_cols.model.get_iter_first (out iter);
		while (iterExists) {
			TreeViewListColumn item;
			tv_cols.model.get (iter, 1, out item, -1);
			list.add(item);
			iterExists = tv_cols.model.iter_next (ref iter);
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


