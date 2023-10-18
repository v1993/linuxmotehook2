project('linuxmotehook2', ['c', 'vala'],
          version: '0.2.1',
    meson_version: '>= 0.55.0',
  default_options: [
                     'warning_level=2',
                     'default_library=static'
                   ],
)

extra_vapi_dir = meson.current_source_dir() / 'vapi'

xwiimote_proj = subproject('xwiimote')
xwiimote_dep  = xwiimote_proj.get_variable('xwiimote_dep')

gcemuhook_proj = subproject('gcemuhook')
gcemuhook_dep  = gcemuhook_proj.get_variable('gcemuhook_dep')

subdir('src')

install_data('ExampleConfig.ini', install_dir : get_option('datadir') / 'doc' / 'linuxmotehook2')
