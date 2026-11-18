#!/usr/bin/ruby
#
# This file is part of CPEE-LLM-DNAMES.
#
# CPEE-LLM-DNAMES is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# CPEE-LLM-DNAMES is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# CPEE-LLM-DNAMES (file LICENSE in the main directory). If not, see
# <http://www.gnu.org/licenses/>.

require 'riddl/server'
require 'riddl/client'
require 'json'

module CPEE
  module LLM
    module Dnames
      SERVER = File.expand_path(File.join(__dir__,'implementation.xml'))
      USED_TOKENS_HEADER = 'CPEE-LLM-Used-Tokens'

      class FindDocuments < Riddl::Implementation #{{{
        def used_tokens(tokens)
          t = Array(tokens).first.to_s
          @headers << Riddl::Header.new(USED_TOKENS_HEADER, "input=#{t[/input=(\d+)/,1].to_i}, output=#{t[/output=(\d+)/,1].to_i}")
          @headers << Riddl::Header.new('Access-Control-Expose-Headers', USED_TOKENS_HEADER)
        end

        SYSTEM_PROMPT = <<~PROMPT #{{{
          You resolve references to documents inside free-form process instructions.

          You will be given a JSON object mapping known document names to their
          URLs, followed by a user instruction. The instruction may refer to one
          or more of those documents by name, using any natural phrasing, for
          example: an exact or slightly misspelled name on its own, "the X
          document", "a document named X", "a document called X", "a document
          identified by the name X", or similar constructions.

          Task: return the user instruction verbatim, except that every phrase
          referring to one of the known documents by name is replaced with that
          document's URL taken from the mapping. Keep all surrounding wording
          (e.g. "document", "named", "called", punctuation) untouched -- replace
          only the name itself. Do not resolve or invent references to documents
          that are not in the mapping, and do not alter any other part of the
          text.

          Output only the resulting text: no explanation, no quotes, no
          markdown or code fences.
        PROMPT
        #}}}

        def response
          user_input    = @p.find { |p| p.name == 'user_input' }.value.read
          llm           = @p.find { |p| p.name == 'llm' }.value.read
          documents_raw = @p.find { |p| p.name == 'documents' }.value.read
          documents     = JSON.parse(documents_raw)

          if documents.empty?
            used_tokens('input=0, output=0')
            return Riddl::Parameter::Complex.new('response', 'text/plain', user_input)
          end

          system_prompt = "#{SYSTEM_PROMPT}\nKnown documents:\n#{documents_raw}"

          status, res, rheaders = Riddl::Client.new(@a[0][:generic_endpoint]).post([
            Riddl::Parameter::Complex.new('llm', 'text/plain', llm),
            Riddl::Parameter::Complex.new('user_input', 'text/plain', user_input),
            Riddl::Parameter::Complex.new('system_prompt', 'text/plain', system_prompt),
            Riddl::Parameter::Complex.new('format', 'text/plain', 'false')
          ])
          used_tokens((rheaders || {})['CPEE_LLM_USED_TOKENS'])

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
            run FindDocuments, opts if put 'docin'
          end
        end
      end
    end
  end
end
