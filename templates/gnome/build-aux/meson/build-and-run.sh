if [ ! -e _build ]
then
    meson _build -Dprefix=$(pwd)/app
fi \
&& ninja -C _build \
&& ninja -C _build install \
&& env \
    GSETTINGS_SCHEMA_DIR=./app/share/glib-2.0/schemas \
    LD_LIBRARY_PATH=./app/lib64/${APP_NAME} \
    ./app/bin/${APP_NAME}
