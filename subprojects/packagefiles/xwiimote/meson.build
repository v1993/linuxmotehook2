project('xwiimote', ['c'],
          version: '2.0.1',
    meson_version: '>= 0.50.0'
)

libudev = dependency('libudev')

xwiimote_sources = [
  'lib/core.c',
  'lib/monitor.c'
]

xwiimote_lib = library('xwiimote', xwiimote_sources,
  dependencies: [libudev],
  install: false,
  c_args: ['-DXWII__EXPORT=', '-D_GNU_SOURCE', '-Wno-override-init', '-Wno-sign-compare'],
  override_options : ['c_std=gnu99']
)

xwiimote_dep = declare_dependency(link_with : xwiimote_lib, include_directories: 'lib')
