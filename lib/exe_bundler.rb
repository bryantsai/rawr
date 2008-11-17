require 'fileutils'
require 'bundler'
require 'platform'

module Rawr
  class ExeBundler < Bundler  
    include FileUtils

    def deploy(options)
      @project_name = options.project_name
      @classpath = options.classpath
      @main_java_class = options.main_java_file
      @built_jar_path = options.jar_output_dir
      
      @java_app_deploy_path = options.windows_output_dir
      @target_jvm_version = options.target_jvm_version
      @jvm_arguments = options.jvm_arguments

      @startup_error_message     = options.windows_startup_error_message
      @bundled_jre_error_message = options.windows_bundled_jre_error_message
      @jre_version_error_message = options.windows_jre_version_error_message
      @launcher_error_message    = options.windows_launcher_error_message
      
      @launch4j_config_file = "#{@java_app_deploy_path}/configuration.xml"

      copy_deployment_to @java_app_deploy_path
      puts "Creating Windows application in #{@built_jar_path}/#{@project_name}.exe"

      File.open(@launch4j_config_file, 'w') do |file|
        file << <<-CONFIG_ENDL
<launch4jConfig>
<dontWrapJar>true</dontWrapJar>
<headerType>0</headerType>
<jar>#{@project_name}.jar</jar>
<outfile>#{@java_app_deploy_path}/#{@project_name}.exe</outfile>
<errTitle></errTitle>
<jarArgs></jarArgs>
<chdir></chdir>
<customProcName>true</customProcName>
<stayAlive>false</stayAlive>
<icon></icon>
<jre>
  <path></path>
  <minVersion>#{@target_jvm_version}.0</minVersion>
  <maxVersion></maxVersion>
  <initialHeapSize>0</initialHeapSize>
  <maxHeapSize>0</maxHeapSize>
  #{"<args>" + @jvm_arguments + "</args>" unless @jvm_arguments.nil? || @jvm_arguments.strip.empty?}
</jre>
<messages>
  <startupErr>#{@startup_error_message}</startupErr>
  <bundledJreErr>#{@bundled_jre_error_message}</bundledJreErr>
  <jreVersionErr>#{@jre_version_error_message}</jreVersionErr>
  <launcherErr>#{@launcher_error_message}</launcherErr>
</messages>
</launch4jConfig>          
CONFIG_ENDL
      end
      if Platform.instance.using_windows?
        #CACLS
        sh "echo y | cacls #{File.dirname(__FILE__)}/launch4j/bin/windres.exe /G #{ENV['USERNAME']}:F"
        sh "echo y | cacls #{File.dirname(__FILE__)}/launch4j/bin/ld.exe /G #{ENV['USERNAME']}:F"
      else
        chmod 0755, "#{File.dirname(__FILE__)}/launch4j/bin/windres"
        chmod 0755, "#{File.dirname(__FILE__)}/launch4j/bin/ld"
      end
      sh "java -jar #{File.dirname(__FILE__)}/launch4j/launch4j.jar #{@launch4j_config_file}"
    end
  end
end