

sudo install -m 0644 apps.selene.gschema.xml /usr/share/glib-2.0/schemas
sudo glib-compile-schemas /usr/share/glib-2.0/schemas/
echo Done.
read dummy
