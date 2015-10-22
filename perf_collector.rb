require 'json'

class PerfCallRunner
  def self.median(array)
    sorted = array.sort
    len = sorted.length

    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end

  def self.get_stats(call_time_list)
    {
      median: median(call_time_list),
      mean: call_time_list.inject(:+) / call_time_list.length,
      samples: call_time_list.length,
      min: call_time_list.min,
      max: call_time_list.max,
    }
  end
end

n_times = ARGV[0]
curl_args = ARGV[1..-1].join(" ") if ARGV[1..-1]

unless n_times && curl_args
  puts "usage: ruby perf_collector.rb [n_times] [curl_arguments]"
  exit 1
end

puts "\nexecuting #{n_times} times:\n\ncurl #{curl_args}\n\n"

call_time_list = n_times.to_i.times.map do |n|
  puts "#{n+1} / #{n_times}"
  output = `curl #{curl_args} 2>&1`

  raise("not success (run #{n})") unless output.match(/200 OK/)

  time_line = output.match(/X-Runtime: (\d\.\d+)/)
  if time_line
    time = time_line[1]
    time.to_f
  else
    raise "no X-Runtime line found in output #{n}"
  end
end

puts "\n\n"
puts JSON.pretty_unparse(PerfCallRunner.get_stats(call_time_list))
