linuxmotehook2_sources = [
  'ExtensionDevice.vala',
  'MainDevice.vala',
  'Nunchuck.vala',
  'Server.vala',

  'main.vala'
]

linuxmotehook2_deps = [
  dependency('glib-2.0',      version: '>= 2.50'),
  dependency('gio-2.0',       version: '>= 2.50'),
  dependency('gio-unix-2.0',  version: '>= 2.50'),
  dependency('gcemuhook-0.1'),

  xwiimote_dep,
  meson.get_compiler('vala').find_library('xwiimote', dirs: xwiimote_vapi_dir),
]

linuxmotehook2 = executable ('linuxmotehook2', linuxmotehook2_sources,
  dependencies: linuxmotehook2_deps,
  install: true,

  vala_args: [
    #'--enable-experimental-non-null',
    '--vapidir', xwiimote_vapi_dir
  ],

  c_args: [
    '-DLM_VERSION="@0@"'.format(meson.project_version())
  ]
)
