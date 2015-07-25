/*
 * FileInfoWindow.vala
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

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

public class EncoderStatusWindow : Dialog {

	private Box vboxMain;
	private Box vbox_actions;
	private Button btnOk;
	private Button btnRefesh;
	private TreeView tv;
	private ScrolledWindow sw;
	
	public EncoderStatusWindow () {
		title = _("Encoders");
		set_default_size (500, 450);
		
        window_position = WindowPosition.CENTER_ON_PARENT;
        destroy_with_parent = true;
        skip_taskbar_hint = true;
		modal = true;
		deletable = true;
		icon = get_app_icon(16);

		// get content area
		vboxMain = get_content_area();
		vboxMain.margin = 6;

		// get action area
		vbox_actions = (Box) get_action_area();

	    tv = new TreeView();
		tv.get_selection().mode = SelectionMode.NONE;
		tv.headers_visible = true;
		tv.set_rules_hint (true);
		
		sw = new ScrolledWindow(null, null);
		sw.set_shadow_type (ShadowType.ETCHED_IN);
		sw.add (tv);
		sw.expand = true;
		vboxMain.add(sw);

		TreeViewColumn col_icon = new TreeViewColumn();
		//col_icon.title = _("");
		col_icon.resizable = true;
		tv.append_column(col_icon);
		
		CellRendererPixbuf cell_icon = new CellRendererPixbuf ();
		col_icon.pack_start (cell_icon, false);
		col_icon.set_attributes(cell_icon, "pixbuf", 3);
		
		TreeViewColumn col_cmd = new TreeViewColumn();
		col_cmd.title = " " + _("Encoding Tool") + " ";
		tv.append_column(col_cmd);

		CellRendererText cell_cmd = new CellRendererText ();
		col_cmd.pack_start (cell_cmd, false);
		col_cmd.set_attributes(cell_cmd, "text", 0);
		
		TreeViewColumn col_desc = new TreeViewColumn();
		col_desc.title = " " + _("Description") + " ";
		tv.append_column(col_desc);
		
		CellRendererText cell_desc = new CellRendererText ();
		col_desc.pack_start (cell_desc, false);
		col_desc.set_attributes(cell_desc, "text", 1);
		
		TreeViewColumn col_status = new TreeViewColumn();
		col_status.title = " " + _("Status") + " ";
		tv.append_column(col_status);
		
		CellRendererText cell_status = new CellRendererText ();
		col_status.pack_start (cell_status, false);
		col_status.set_attributes(cell_status, "text", 2);
		
		tv_refresh();
		
		//btnRefesh
        btnRefesh = new Button.with_label("   " + _("Refresh") + "   ");
		vbox_actions.add(btnRefesh);
		btnRefesh.clicked.connect(()=>{
			gtk_set_busy(true,this);
			App.check_all_encoders();  
			tv_refresh();
			gtk_set_busy(false,this);
		});
		
        //btnOk
        btnOk = (Button) add_button ("gtk-ok", Gtk.ResponseType.ACCEPT);
        btnOk.clicked.connect (() => {  destroy();  });
	}
	
	public void tv_refresh(){
		TreeStore store = new TreeStore (4, typeof (string), typeof (string), typeof (string), typeof(Gdk.Pixbuf));
		
		//status icons
		Gdk.Pixbuf pix_ok = null;
		Gdk.Pixbuf pix_missing = null;

		try{
			pix_ok = new Gdk.Pixbuf.from_file("/usr/share/selene/images/item-green.png");
			pix_missing  = new Gdk.Pixbuf.from_file("/usr/share/selene/images/item-red.png");
		}
        catch(Error e){
	        log_error (e.message);
	    }
	    
		foreach (Encoder enc in App.Encoders.values){
			TreeIter iter;
			store.append(out iter, null);
			store.set(iter, 0, enc.Command);
			store.set(iter, 1, enc.Name);
			store.set(iter, 2, enc.IsAvailable ? _("Found") : _("Missing"));
			store.set(iter, 3, enc.IsAvailable ? pix_ok : pix_missing);
		}
		
		tv.set_model (store);
	}
}
