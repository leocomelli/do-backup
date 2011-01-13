#!/usr/bin/ruby

require 'yaml'
require 'email'

def init
  @yaml = YAML::load(File.open("config.yml"))
  @destino = @yaml['diretorio.destino']
  @data = Time.now.strftime("%d%m%Y_%H%M%S")

  log "***********************************************"
  log "Iniciando backup #{Time.now.day}/#{Time.now.month}/#{Time.now.year}"
  log "***********************************************"
end

def compactar(origem, destino)
  if not File.exists? destino
    log "Compactando arquivo #{origem}..."
    system("zip -9 #{destino} #{origem}")
  else
    log "Adicionando o arquivo #{origem} no arquivo #{destino}"
    system("zip -u #{destino} #{origem}")
  end 

  remover_arquivo origem
end

def remover_arquivo(nome)
  log "Removendo arquivo #{nome}..."
  system("rm -f #{nome}")
end

def backup_mysql
  usuario = @yaml['mysql.usuario']
  senha = @yaml['mysql.senha']
  bancos = @yaml['mysql.bancos']

  nome_arquivo_compactado = @destino + File::SEPARATOR + "bd_" + @data + ".zip"

  bancos.each do |banco|
    log "Fazendo backup do banco de dados #{banco}"
    nome_arquivo = @destino + File::SEPARATOR + banco + ".sql"
    system("mysqldump -u#{usuario} -p#{senha} --databases #{banco} > #{nome_arquivo}")

    compactar nome_arquivo, nome_arquivo_compactado    
  end

  return nome_arquivo_compactado
end

def backup_svn(repos, name)
  svn_dir = @yaml['svn.dir']

  nome_arquivo_compactado = @destino + File::SEPARATOR + "svn_#{name}_" + @data + ".zip"

  repos.each do |repo|
    log "Fazendo backup do repositorio #{repo}"
    nome_arquivo = @destino + File::SEPARATOR + repo + ".dump"
    system("svnadmin dump #{svn_dir}/#{repo} > #{nome_arquivo}")

    compactar nome_arquivo, nome_arquivo_compactado    
  end

  return nome_arquivo_compactado
end

def enviar_email(email, *arquivos)
    log "Enviando email para #{email}"
    mail = Email.new(@yaml['email.smtp'],@yaml['email.porta'])
    mail.hello_domain   = @yaml['email.dominio']
    mail.auth_login     = @yaml['email.usuario']
    mail.auth_passw     = @yaml['email.senha']
    mail.auth_type      = :plain
    mail.from           = {:nome => @yaml['email.de.nome'], :email => @yaml['email.de.endereco']}
    mail.to             = email
    mail.subject        = @yaml['email.assunto'] << "#{Time.now.day}/#{Time.now.month}/#{Time.now.year}"
    mail.text           = ""
    mail.html           = @yaml['email.corpo']

    arquivos.each do |arquivo|
      nome_arq = arquivo.split(File::SEPARATOR)
      mail.attach_file(arquivo,nome_arq[nome_arq.size-1])
    end

    begin
      mail.send()
    rescue
      log "Erro ao enviar o email: #{$!}"
    end
end

def log(info)
  File.open(@yaml['log.arquivo'], 'a') do |f|
    f << info + "\n"
  end
end

init

arquivo_bd = backup_mysql
arquivo_svn = backup_svn 'repo_name', 'repo_alias'

enviar_email 'usuario@server.com.br', arquivo_bd, arquivo_svn

