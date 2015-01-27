require 'tmpdir'

module Thrust
  class SpecLauncher
    def initialize(out = $stdout, thrust_executor = Thrust::Executor.new)
      @thrust_executor = thrust_executor
      @out = out
    end

    def run(executable_name, build_configuration, build_sdk, os_version, device_name, timeout, build_dir, simulator_binary, environment_variables)
      if build_sdk.include?('macosx')
        build_path = File.join(build_dir, build_configuration)
        app_executable = File.join(build_path, executable_name)
        @thrust_executor.check_command_for_failure("\"#{app_executable}\"", {'DYLD_FRAMEWORK_PATH' => "\"#{build_path}\""})
      else
        device_type_id = "com.apple.CoreSimulator.SimDeviceType.#{device_name}, #{os_version}"
        app_executable = File.join(build_dir, "#{build_configuration}-#{build_sdk}", "#{executable_name}.app")
        simulator_binary ||= 'ios-sim'
        output_file = "tmp/thrust_specs_output"

        arguments = ["--devicetypeid \"#{device_type_id}\"",
                     "--timeout #{timeout || '30'}",
                     "--stdout #{output_file}",
                     "--setenv CFFIXED_USER_HOME=\"#{Dir.tmpdir}\"",]

        environment_variables.each do |key, value|
          arguments << "--setenv #{key}=\"#{value}\""
        end

        @thrust_executor.system_or_exit("#{simulator_binary} launch #{app_executable} #{arguments.compact.join(' ')}")

        results = File.read(output_file)
        FileUtils.rm_r('tmp')

        @out.puts 'Results:'
        @out.puts results

        results.include?("Finished") && !results.include?("FAILURE") && !results.include?("EXCEPTION")
      end
    end
  end
end
