# frozen_string_literal: true

# Configure Autoprefixer to generate source maps for easier debugging of CSS
# See: https://github.com/tablecheck/dartsass-sprockets/issues/23#issuecomment-2408131105
class AutoprefixerWithSourcemap < AutoprefixerRails::Sprockets
  def self.run(filename, css)
    output = "#{filename.chomp(File.extname(filename))}.css"

    # If you want this nice an generic, you could check `css` for the presence
    # of an inline source map, and set the `map` argument based on that
    # instead of always setting it to `true`.
    result = @processor.process(css, from: filename, to: output, map: true)

    result.warnings.each do |warning|
      warn "autoprefixer: #{warning}"
    end

    result.css
  end

  def self.use_bundle_processor?
    ::Sprockets::VERSION.to_f >= 4
  end

  def self.install(env)
    if use_bundle_processor?
      env.register_bundle_processor('text/css', self)
    else
      env.register_postprocessor('text/css', self)
    end
  end

  def self.uninstall(env)
    if use_bundle_processor?
      env.unregister_bundle_processor('text/css', self)
    else
      env.unregister_postprocessor('text/css', self)
    end
  end
end

Rails.application.config.assets.configure do |env|
  AutoprefixerRails.uninstall(env)
  AutoprefixerWithSourcemap.register_processor(AutoprefixerRails.processor({}))
  AutoprefixerWithSourcemap.install(env)
end
