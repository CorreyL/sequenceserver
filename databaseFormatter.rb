# copyright yannick . wurm at unil . ch
# Finds files, reads first char. if its '>', read 500 lines. Guess sequence type, ask user for title to format as blast database.

require 'ptools' # for File.binary?(file)
require 'find'
require 'logger'
require 'lib/sequencehelpers.rb'

LOG = Logger.new(STDOUT)

$stdin.sync = true
$stdout.sync = true

class DatabaseFormatter
    include SequenceHelpers

    def format_databases(db_path)
        Find.find(db_path) do |file|
            next if File.directory?(file)

            unless File.binary?(file)
                if probably_fasta?(file)
                    LOG.info("Found #{file}")
                    ## guess whether protein or nucleotide based on first 500 lines
                    first_lines = ''
                    File.open(file, 'r') do |file_stream|
                        file_stream.each do |line|
                            first_lines += line
                            break if file_stream.lineno == 500
                        end
                    end
                    sequence_type = type_of_sequences(first_lines) # returns :protein or :nucleotide
                    if [ :protein, :nucleotide].include?(sequence_type)
                        ask_make_db(file, sequence_type)
                    else 
                        LOG.warn("Unable to guess sequence type for #{file}. Skipping") 
                    end
                end
            end
        end
    end

    def probably_fasta?(file)
        File.open(file, 'r') do |file_stream|
            first_line = file_stream.readline
            if first_line[0] == '>'
                return TRUE
            else 
                return FALSE
            end
        end
    end


    def ask_make_db(file, type)
        LOG.info("FASTA file: #{file}")
        LOG.info("Fasta type: " + type.to_s)
        
        response = ''
        until response.match(/^[yn]$/i) do
            LOG.info("Proceed? [y/n]: ")
            response = gets.chomp
        end
        puts "asdfasd"
        if response.match(/y/i)
            LOG.info("Enter a database title (or will use '#{file.basename}'")
            title = gets.chomp
            title = file.basename  if title.empty?
            
            make_db(file,type,title)
        end
    end

    def make_db(file,type, title)
        LOG.info("Will make #{type.to_s} database from #{file} with #{title}")
        command = "makeblastdb -in #{file} -db_type #{ type.to_s.slice(0,4)} -title #{title} "
        %x|#{ command}|  
    end
end



if ARGV.length == 1
    db_path = ARGV[0]
    LOG.info("running with #{db_path}")
    if File.directory?(db_path) 
        app = DatabaseFormatter.new()
        app.format_databases(db_path)
    else
        LOG.warn('Not running')
    end
else 
    LOG.warn('Not running: give only one argument (directory)')
end