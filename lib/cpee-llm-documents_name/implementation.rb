#!/usr/bin/ruby
#
# This file is part of CPEE-LLM-DOCUMENTS_NAME.
#
# CPEE-LLM-DOCUMENTS_NAME is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# CPEE-LLM-DOCUMENTS_NAME is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with CPEE-LLM-DOCUMENTS_NAME (file LICENSE in the main directory). If not, see
# <http://www.gnu.org/licenses/>.

require 'riddl/server'
require 'riddl/client'
require 'open-uri'
require 'json'

module CPEE
  module LLMDocumentsName
    SERVER = File.expand_path(File.join(__dir__,'implementation.xml'))

    class DoDocument < Riddl::Implementation #{{{
      def response
        llm           = @p.find { |p| p.name == 'llm' }.value.read
        user_input    = @p.find { |p| p.name == 'user_input' }.value.read
        document_urls = JSON.parse(@p.find { |p| p.name == 'documents' }.value.read)

        documents = document_urls.map do |url|
          f = URI.parse(url).open
          Riddl::Parameter::Complex.new('documents', f.content_type || 'application/octet-stream', f, File.basename(URI.parse(url).path))
        end

        status, res = Riddl::Client.location(@a[0][:generic_endpoint]).resource.post([
          Riddl::Parameter::Simple.new('llm', llm),
          Riddl::Parameter::Simple.new('user_input', user_input),
          Riddl::Parameter::Simple.new('system_prompt', ''),
          Riddl::Parameter::Simple.new('format', 'false')
        ] + documents)

        raw = res.first.value
        raw = raw.read if raw.respond_to?(:read)
        result = JSON.parse(raw)

        if status < 200 || status >= 300 || result['error']
          @status = 502
          return Riddl::Parameter::Complex.new('response', 'text/plain', (result['error'] || raw).to_s)
        end

        Riddl::Parameter::Complex.new('response', 'text/plain', result['llm_response'].to_s)
      end
    end #}}}

    def self::implementation(opts)
      opts[:generic_endpoint] ||= 'http://localhost:9305/generic/'

      Proc.new do
        on resource do
          run DoDocument, opts if put 'docin'
        end
      end
    end
  end
end
