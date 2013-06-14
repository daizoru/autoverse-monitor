module.exports = ->

  @initConfig

    pkg: @file.readJSON 'package.json'

    coffee: 
      build:
        expand: yes
        flatten: no
        cwd: 'src/'
        src: ['**/*.coffee']
        dest: 'public/js/'
        ext: '.js'
    
    ###
    copy:
      main:
        files: [
          {
            expand: no
            cwd: 'public/'
            src: [
              'components/threejs/examples/textures'
              'components/threejs/examples/models'
            ]
            dest: '.'
          }
        ]
    ###

    concat:
      options:
        stripBanners: yes
        #banner: """/*! <%= pkg.name %> - v<%= pkg.version %> -
        #  <%= grunt.template.today("yyyy-mm-dd") %> */"""

      vendors:
        src: [
          'components/threejs/build/three.js'

          # STATS AND WEBGL DETECTOR
          'components/stats.js/build/stats.min.js'
          'components/threejs/examples/js/Detector.js'

          # DAT.GUI
          'components/dat-gui/build/dat.color.js'
          'components/dat-gui/build/dat.gui.js'

          # CONTROLS
          'components/threejs/examples/js/controls/TrackballControls.js'
          
          # POST-PROCESSING
          'components/threejs/examples/js/postprocessing/EffectComposer.js'
          'components/threejs/examples/js/postprocessing/RenderPass.js'
          'components/threejs/examples/js/postprocessing/BloomPass.js'
          'components/threejs/examples/js/postprocessing/ShaderPass.js'
          'components/threejs/examples/js/postprocessing/MaskPass.js'
          'components/threejs/examples/js/postprocessing/SavePass.js'

          # SHADERS
          'components/threejs/examples/js/shaders/BleachBypassShader.js'
          'components/threejs/examples/js/shaders/ConvolutionShader.js'
          'components/threejs/examples/js/shaders/CopyShader.js'
          'components/threejs/examples/js/shaders/HorizontalTiltShiftShader.js'
          'components/threejs/examples/js/shaders/HorizontalBlurShader.js'
          'components/threejs/examples/js/shaders/VerticalBlurShader.js'
          'components/threejs/examples/js/shaders/LuminosityShader.js'
          'components/threejs/examples/js/shaders/NormalMapShader.js'
          'components/threejs/examples/js/shaders/VerticalTiltShiftShader.js'

          # SHADER TERRAIN
          'components/threejs/examples/js/ShaderTerrain.js'

          # PHYSIC ENGINE
          'components/cannon.js/build/cannon.js'

        ]
        dest: 'public/js/vendors.js'


    uglify:
      options: mangle: no
      #vendor: 
      #  files: 'lib/logger.min.js': 'lib/logger.js'

    watch:
      coffee:
        files: [ 'src/**/*.coffee' ]
        tasks: [ 'coffee' ]
        options: debounceDelay: 250

    bgShell:
      _defaults: bg: no

  @loadNpmTasks 'grunt-contrib-uglify'
  @loadNpmTasks 'grunt-contrib-coffee'
  @loadNpmTasks 'grunt-contrib-watch'
  @loadNpmTasks 'grunt-contrib-concat'  
  @loadNpmTasks 'grunt-contrib-copy'
  @loadNpmTasks 'grunt-bg-shell'


  @registerTask 'build', [
    'coffee'
    #'copy'
    'concat'
  ]

  @registerTask 'default', [
    'build'
  ]