project('linuxmotehook2', ['c', 'vala'],
          version: '0.1.4',
    meson_version: '>= 0.50.0',
  default_options: [ 'warning_level=2',
                   ],
)

subdir('externals')
subdir('src')

install_data('ExampleConfig.ini', install_dir : get_option('datadir') / 'linuxmotehook2')
