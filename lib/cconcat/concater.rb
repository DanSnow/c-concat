#!/usr/bin/env ruby
# encoding: UTF-8

require 'set'

module CConcat
  class Concater
    HEADER = <<-EOD.gsub(/^\s{4}/, '')
    /*
     * This file is auto generate by cconcat #{CConcat::VERSION}
     * Project home: https://github.com/DanSnow/cconcat
     */
     #define _GNU_SOURCE
    EOD

    HEADER_FILE_REGEX = /^#include\s*"(.*)"/
    attr_reader :entry_file

    def initialize(entry_file)
      @entry_file = entry_file
      @sources = Set.new
    end

    def concat
      output = HEADER.split("\n")
      source_files = [@entry_file]
      until source_files.empty?
        filename = source_files.pop
        next unless File.exist? filename
        output += expand_header(filename, source_files)
      end
      output.join("\n")
    end

    private

    def read_lines(filename)
      IO.readlines filename
    end

    def expand_header(filename, source_files)
      result = ["// #{filename}"]
      lines = read_lines filename
      lines.each do |line|
        process_line line, source_files, result
      end
      result << "// End #{filename}"
    end

    def process_line(line, source_files, result)
      if header_line? line
        name = header_name line
        insert_header result, name
        source = source_name(name)
        unless @sources.include? source
          source_files << source_name(name)
          @sources << source
        end
      else
        result << line.chomp
      end
    end

    def insert_header(result, name)
      result << %(// #include "#{name}")
      result.concat File.read(name).split("\n")
      result << '// End include'
    end

    def header_line?(line)
      !(line =~ HEADER_FILE_REGEX).nil?
    end

    def header_name(line)
      m = line.match(HEADER_FILE_REGEX)
      m[1]
    end

    def source_name(name)
      File.basename(name, '.h') + '.c'
    end
  end
end
