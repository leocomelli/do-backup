#!/usr/bin/ruby

# RubyMail
# Esta classe foi desenvolvida por Gustavo Lichti Mendonça
# Mail/Gtalk: gustavo.lichti@gmail.com - www.lichti.eti.br
# Msn: gustavo@emotiongames.com.br
#
# Esta classe tem como objetivo enviar emails com anexos,
# textos formatados em html e textos planos, através através
# do protocolo SMTP.
#
# Esta classe não esta otimizada, uma das coisas a fazer são
# os controles de erros. Mas esta funcional
#
# Espero receber opiniões ou sugestões de mudança para que eu
# possa disponibilizar aqui para outras pessoas também possam
# utilizar
#
# Um dos itens que vou adicionar em uma TO-DO-LIST é suporte a
# SSL/TLS, para que possamos utilizar o gmail também.
#
# Fiz essas classes com fins de estudos, com o objetivo que ela
# funcionasse!
#
# Após criada a classe eu queria um utilização então criei o
# PornMail, que pega ensaios fotográficos e envia para os
# colegas todos os dias as 2 horas da manhã. ;)
#
# Pagina deste projeto: www.lichti.eti.br/RubyMail
#
# Referencia a classe net/smtp => http://www.ruby-doc.org/stdlib/libdoc/net/smtp/rdoc/index.html
#
# Usando o RubyMail
#
#    mail = Email.new('mail.domain.eti.br',25)
#    mail.hello_domain   = 'domain.eti.br'
#    mail.auth_login     = 'guest@domain.eti.br'
#    mail.auth_passw     = '*******
#    mail.auth_type      = :plain
#    mail.from           = {:nome => "\"RubyMail\"", :email => "RubyMail@guest@domain.eti.br"}
#    mail.to             = "colega@gmail.com"
#    mail.subject        = "Testando o RubyMail- #{Time.now.day}/#{Time.now.month}/#{Time.now.year}"
#    mail.text           = "Esse e-mail é um teste do ruby mail em HTML mas seu cliente de e-mail não deve suportar"
#    mail.html           = "<h1>Teste do RubyMail</h1>"
#    mail.attach_file("/home/guest/bola.jpg","bola.jpg")
#    begin
#      mail.send()
#    rescue
#      puts "error on sending: #{$!}"
#    end
#


require "net/smtp"
class Email
  attr_accessor :html,:text,:server,:from,:to,:cc,:bcc,:subject,:port,:hello_domain,:auth_login,:auth_passw,:auth_type

  def initialize(server=nil,port=nil)
    server        ||= "localhost"
    port          ||= 25
    @server       = server
    @port         = port
    @boundary     = createBoundary()
    @boundary_sec = createBoundary()
    @hello_domain = nil
    @auth_login   = nil
    @auth_passw   = nil
    @auth_type    = nil
    @attachments  = []
    @subject      = "no subject"
    @from         = ""
    @to           = []
    @cc           = []
    @bcc          = []
    @html         = ""
    @text         = ""
  end

  def createBoundary()
    return ["----=_RubyMail_Part_"]  +   uniqueNumber()
  end
  private :createBoundary

  def uniqueNumber()
    return [
    sprintf("%02X", rand(999999990000000)),
    sprintf("%02X", Time.new.to_i),
    sprintf("%02X", $_),
    sprintf("%02X", Time.new.usec())
    ]
  end
  private :uniqueNumber

  def content_type(filename)
    filename = File.basename(filename).downcase
    return "image/jpg"       if (filename =~ /\.jp(e?)g$/)
    return "image/gif"       if (filename =~ /\.gif$/)
    return "text/html"       if (filename =~ /\.htm(l?)$/)
    return "text/plain"      if (filename =~ /\.txt$/ )
    return "application/zip" if (filename =~ /\.zip$/)
    # Outros tipos ?!
    return "application/octet-stream"
  end
  private :content_type

  def attach_file(phy_filename, real_filename)
    begin
      f = File.new(phy_filename);
      data = f.read()
      f.close()
    rescue
      return false
    end
    data = [data].pack("m*");
    real_filename = phy_filename if (real_filename=="")
    attachment = {"type" => content_type(real_filename),
                  "name" => File.basename(real_filename),
                  "data" => data }
    @attachments << attachment
  end

  def todos_email
    todos = []
    todos.concat @to unless @to.empty?
    todos.concat @cc unless @cc.empty?
    todos.concat @bcc unless @bcc.empty?
  end

  def send()
    raise "Servidor de e-mail não especificado"      if @server.empty?
    raise "Email do remetente não especificado"      if @from.empty?
    raise "Email do destinatario não especificado"   if @to.empty? && @cc.empty? && @bcc.empty?
    Net::SMTP.start(@server,@port,@hello_domain,@auth_login,@auth_passw,@auth_type) do |smtp|
      smtp.ready(@from['email'], @to) do |wa|
        wa.write("reply-To: #{@from[:email]}\r\n")
        wa.write("from: #{@from[:nome]}<#{@from[:email]}>\r\n")
        wa.write("to: #{@to[0]}\r\n") unless @to.empty?
        wa.write("cc: #{@cc[0]}\r\n") unless @cc.empty?
        wa.write("subject: #{@subject}\r\n")
        wa.write("MIME-Version: 1.0\r\n")
        unless(@attachments.empty?)
          wa.write("Content-Type: multipart/mixed; boundary=\"#{@boundary}\"\r\n")
          wa.write("\r\n")
        end
        unless(@html.empty?)
          wa.write("--#{@boundary}\r\n") unless(@attachments.empty?)
          wa.write("Content-Type: multipart/alternative; boundary=\"#{@boundary_sec}\"\r\n")
          wa.write("\r\n")
        end
        # add text part if given
        unless(@text.empty?)
          # add boundary if we are multiparted, otherwise just add text
          if((!@attachments.empty?) || (!@html.empty?))
            unless (@html.empty?)
              wa.write("--#{@boundary_sec}\r\n")
            else
              wa.write("--#{@boundary}\r\n")
            end
            wa.write("Content-Type: text/plain; charset=iso-8859-1\r\n")
            wa.write("Content-Transfer-Encoding: 7BIT\r\n")
            wa.write("Content-Disposition: inline\r\n")
            # we don't take care of very old mail servers with bit only
          else
            # if only text and no attachm. we give the encoding
            wa.write("Content-Type: text/plain; charset=iso-8859-1\r\n")
            wa.write("Content-Transfer-Encoding: 7BIT\r\n")
          end
          wa.write("\r\n")
          wa.write("#{@text}\r\n")
          wa.write("\r\n")
        end
        unless(@html.empty?)
            wa.write("--#{@boundary_sec}\r\n")
            wa.write("Content-Type: text/html; charset=ISO-8859-1\r\n")
            wa.write("Content-Transfer-Encoding: 7BIT\r\n")
            wa.write("Content-Disposition: inline\r\n")
            wa.write("\r\n")
            wa.write("#{@html}\r\n")
            wa.write("\r\n")
            wa.write("--#{@boundary_sec}--\r\n\r\n")
        end

        unless(@attachments.empty?)
          @attachments.each do |part|
            puts "Anexando -> #{part['name']}"
            wa.write("--#{@boundary}\r\n")
            wa.write("Content-Type: #{part['type']}; name=\"#{part['name']}\"\r\n")
            wa.write("Content-Transfer-Encoding: BASE64\r\n")
            wa.write("Content-Disposition: attachment; filename=\"#{part['name']}\"\r\n")
            wa.write("\r\n")
            wa.write("#{part['data']}")  # no more need for \r\n here!
            wa.write("\r\n")
          end
        end

        wa.write("--#{@boundary}--\r\n") unless(@attachments.empty?)
        puts "Email enviado!!!\r\n\r\n"
      end  # smtp.ready(...)
    end
  end
end

