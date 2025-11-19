ffmpeg -i $1 -filter:a loudnorm=print_format=json -f null /dev/null 2>&1 >/dev/null | sed -n '/{/,/}/p' > /tmp/info

ii=`grep \"input_i\" /tmp/info | cut -d: -f2 | tr -cd [:digit:].-`
itp=`grep \"input_tp\" /tmp/info | cut -d: -f2 | tr -cd [:digit:].-`
ilra=`grep \"input_lra\" /tmp/info | cut -d: -f2 | tr -cd [:digit:].-`
it=`grep \"input_thresh\" /tmp/info | cut -d: -f2 | tr -cd [:digit:].-`
to=`grep \"target_offset\" /tmp/info | cut -d: -f2 | tr -cd [:digit:].-`

ffmpeg -i $1 -c:v copy -af loudnorm=linear=true:I=-16:LRA=11:tp=-1.5:measured_I=$ii:measured_LRA=$ilra:measured_tp=$itp:measured_thresh=$it:offset=$to:print_format=summary -y final-$1
