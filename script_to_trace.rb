require "json"
REGEX = /^\s*(?<proc>\S+)\s+(?<tid>-?[0-9]+) \[(?<cpu>[0-9]+)\] (?<time>[0-9]+\.[0-9]+):\s+(?<cat>\S+):(?<event>\S+?)(?:_start|)(?<end>__return|_end|): (?:\(.*\)(?: |$))?(?<args>.*)$/

evs = []
ARGF.each_line do |line|
  # puts line
  line = line.gsub("JS Helper", "JSHelper")
  line = line.gsub("Bluez D-Bus thr", "BluezDbusthr")
  line = line.gsub("dconf worker", "dconfworker")
  if m = line.match(REGEX)
    # p m
    evs << m
  else
    p ["no match", line]
    exit 1
  end
end

# END_REGEX = /(?:__return|_end)$/
spans = {}
evs.each do |m|
  if m[:end] != ""
    spans[m[:event]] = true
  end
end

$started = false
$opened = {}
def print_ev(e)
  return if e[:name].include?('swapper')
  if e[:ph] == 'E' && !$opened[e[:tid]]
    return
  elsif e[:ph] == 'B'
    $opened[e[:tid]] = true
  end

  if $started
    print ","
  else
    $started = true
  end

  puts JSON.dump(e)
end

puts "["
evs.each do |m|
  ts = (m[:time].to_f*1_000_000).to_i
  if m[:event] == "sched_switch"
    if a = m[:args].match(/^prev_comm=(?<from>\S+) .* next_comm=(?<to>\S+) /)
      # p [m[:cpu].to_i, a[:from], a[:to]]
      e1 = {'name': a[:from], 'cat': 'cpu', 'ph': 'E', 'ts': ts, 'pid': 0, 'tid': m[:cpu].to_i, "args": {}}
      e2 = {'name': a[:to], 'cat': 'cpu', 'ph': 'B', 'ts': ts, 'pid': 0, 'tid': m[:cpu].to_i, "args": {}}
      print_ev(e1)
      print_ev(e2)
    else
      p ["not matched", m[:args]]
    end
  else
    ph = 'I'
    if m[:end] != ""
      ph = 'E'
    elsif spans[m[:event]]
      ph = 'B'
    end
    # n = m[:event].gsub(/^\S+:/,'')
    n = m[:event]
    args = m[:args].empty? ? {} : { ph => m[:args]}
    e = {'name': n, 'cat': m[:proc], 'ph': ph, 'ts': ts, 'pid': 1, 'tid': m[:tid].to_i, "args": args}
    print_ev(e)
  end
end
puts "]"
