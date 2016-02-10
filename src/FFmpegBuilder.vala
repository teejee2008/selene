/*
 * FFmpegBuilder.vala
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

public class FFmpegBuilder : Gtk.Window{
	private Gtk.Box vbox_main;
	private Gtk.TreeView tv;
	private Gtk.ScrolledWindow sw;
	private Gtk.ArrayList<FFmpegLibrary> lib_list;
	
	public FFmpegBuilder() {
		set_window_title();
        window_position = WindowPosition.CENTER;
        destroy.connect (Gtk.main_quit);
        set_default_size (550, 20);
        icon = get_app_icon(16);

        //vboxMain
        vbox_main = new Box (Orientation.VERTICAL, 0);
        add (vbox_main);

		/*//tv
		tv = new TreeView();
		tv.get_selection().mode = SelectionMode.MULTIPLE;
		tv.headers_clickable = true;
		tv.set_rules_hint (true);
		tv.set_tooltip_column(3);
		tv.set_activate_on_single_click(true);

		//sw_ppa
		sw_ppa = new ScrolledWindow(null, null);
		sw_ppa.set_shadow_type (ShadowType.ETCHED_IN);
		sw_ppa.add (tv);
		sw_ppa.expand = true;
		vbox_main.add(sw_ppa);

		ListStore model = new ListStore(1, typeof(bool), typeof(string));*/


		
		
	}

	private void init_libs(){
		init_libs_x264();
	}
	
	private void init_libs_x264(){
		FFmpegLibrary lib = new FFmpegLibrary("x264");
		lib_list.add(lib);
		
		lib.Script_Get = """
cd ~/builds

if [ -d "x264/.git" ]; then
	cd x264
	git pull git://git.videolan.org/x264.git
else
	git clone git://git.videolan.org/x264.git
fi
		""";

		lib.Script_Build = """
cd ~/builds/x264
PATH="$HOME/bin:$PATH" 
./configure --prefix="$HOME/builds/ffmpeg" --bindir="$HOME/bin" --enable-static
make
make install
make distclean
		""";
	}

	private void init_libs_x265(){
		FFmpegLibrary lib = new FFmpegLibrary("x265");
		lib_list.add(lib);
		
		lib.Script_Get = """
cd ~/builds

if [ -d "x265/.git" ]; then
	cd x265
	hg pull https://bitbucket.org/multicoreware/x265
else
	hg clone https://bitbucket.org/multicoreware/x265
fi
		""";

		lib.Script_Build = """
cd ~/builds/x265/build/linux
PATH="$HOME/bin:$PATH" 
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/builds/ffmpeg" -DENABLE_SHARED:bool=off ../../source
make
make install
make distclean
		""";
	}

	
	public class FFmpegLibrary : GLib.Object{
		public string Name;
		public string Version;
		public string Script_Get;
		public string Script_Build;

		public FFmpegLibrary(string _name){
			Name = _name;
		}
	}
}
