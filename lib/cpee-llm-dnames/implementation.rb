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
require 'json'

module CPEE
  module LLM
    module Dnames
      SERVER = File.expand_path(File.join(__dir__,'implementation.xml'))

      class FindDocuments < Riddl::Implementation #{{{
        NAME_PATTERN = /\s([a-z_][a-zA-Z0-9_]*)(?=[.!?]|$)/
        def self::resolve_document_names(user_input, documents) #{{{
          return user_input if documents.empty?

          user_input.gsub(NAME_PATTERN) do |match|
            word = $1
            name = documents.keys.min_by { |n| levenshtein(word.downcase, n.downcase) }
            if levenshtein(word.downcase, name.downcase) <= misspelling_threshold(name)
              match.sub(word, documents[name])
            else
              match
            end
          end
        end #}}}
        def self::misspelling_threshold(name) #{{{
          case name.length
          when 0..3 then 0
          when 4..6 then 1
          else 2
          end
        end #}}}
        def self::levenshtein(a, b) #{{{
          costs = (0..b.length).to_a
          a.each_char.with_index(1) do |ca, i|
            nw = costs[0]
            costs[0] = i
            b.each_char.with_index(1) do |cb, j|
              cur = costs[j]
              costs[j] = ca == cb ? nw : [nw, costs[j], costs[j - 1]].min + 1
              nw = cur
            end
          end
          costs[b.length]
        end #}}}

        def response
          user_input = @p.find { |p| p.name == 'user_input' }.value.read
          llm        = @p.find { |p| p.name == 'llm' }.value.read
          documents  = JSON.parse(@p.find { |p| p.name == 'documents' }.value.read)

          resolved_input = self.class.resolve_document_names(user_input, documents)

          Riddl::Parameter::Complex.new('response', 'text/plain', resolved_input)
        end
      end #}}}

      def self::implementation(opts)
        Proc.new do
          on resource do
            run FindDocuments, opts if put 'docin'
          end
        end
      end
    end
  end
end
