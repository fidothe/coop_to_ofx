module OFX
  module Statement
    module Output
      module Builder
        class OFX2 < ::Builder::XmlMarkup
          def ofx_stanza!
            self.instruct!
            self.instruct! :OFX, :OFXHEADER => "200", :VERSION => "203", :SECURITY => "NONE", 
                                 :OLDFILEUID => "NONE", :NEWFILEUID => "NONE"
          end
        end
        
        class OFX1 < ::Builder::XmlMarkup
          def ofx_stanza!
            self.text! <<-EOH
OFXHEADER:100
DATA:OFXSGML
VERSION:103
SECURITY:NONE
ENCODING:USASCII
CHARSET:NONE
COMPRESSION:NONE
OLDFILEUID:NONE
NEWFILEUID:NONE
EOH
          end
          # Create SGMLish markup based on the name of the method. This method
          # is never invoked directly, but is called for each markup method
          # in the markup block.
          # 
          # NB, it's not really SGML, it just doesn't generate empty tags of the form <tag/>
          # Instead it generates <tag>
          # That's it, it's a nasty hack.
          def method_missing(sym, *args, &block)
            text = nil
            attrs = nil
            sym = "#{sym}:#{args.shift}" if args.first.kind_of?(Symbol)
            args.each do |arg|
              case arg
              when Hash
                attrs ||= {}
                attrs.merge!(arg)
              else
                text ||= ''
                text << arg.to_s
              end
            end
            if block
              unless text.nil?
                raise ArgumentError, "XmlMarkup cannot mix a text argument with a block"
              end
              _indent
              _start_tag(sym, attrs)
              _newline
              _nested_structures(block)
              _indent
              _end_tag(sym)
              _newline
            elsif text.nil?
              _indent
              _start_tag(sym, attrs)
              _newline
            else
              _indent
              _start_tag(sym, attrs)
              text! text
              _end_tag(sym)
              _newline
            end
            @target
          end
        end
      end
    end
  end
end
