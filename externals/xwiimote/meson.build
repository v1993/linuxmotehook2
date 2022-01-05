libudev = dependency('libudev')

xwiimote_sources = [
  'src/lib/core.c',
  'src/lib/monitor.c'
]

xwiimote_lib = static_library('xwiimote', xwiimote_sources,
  dependencies: [libudev],
  install: false,
  c_args: ['-DXWII__EXPORT=', '-D_GNU_SOURCE', '-Wno-override-init', '-Wno-sign-compare'],
  override_options : ['c_std=gnu99']
)

xwiimote_dep = declare_dependency(link_with : xwiimote_lib, include_directories: include_directories('src/lib'))

xwiimote_vapi_dir = meson.current_source_dir() / 'vapi'
