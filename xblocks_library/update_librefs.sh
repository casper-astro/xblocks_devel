#!/bin/bash -e

UPDATE="
s,xblocks_library/Accumulators,xblocks_library_accumulators,g;
s,xblocks_library/Communications,xblocks_library_communications,g;
s,xblocks_library/Correlator,xblocks_library_correlator,g;
s,xblocks_library/Delays,xblocks_library_delays,g;
s,xblocks_library/Downconverter,xblocks_library_downconverter,g;
s,xblocks_library/FFTs/Twiddle/coeff_gen,xblocks_library_ffts_twiddle_coeff_gen,g;
s,xblocks_library/FFTs/Twiddle,xblocks_library_ffts_twiddle,g;
s,xblocks_library/FFTs,xblocks_library_ffts,g;
s,xblocks_library/Flow_Control,xblocks_library_flow_control,g;
s,xblocks_library/Misc,xblocks_library_misc,g;
s,xblocks_library/Multipliers,xblocks_library_multipliers,g;
s,xblocks_library/PFBs,xblocks_library_pfbs,g;
s,xblocks_library/Reorder,xblocks_library_reorder,g;
s,xblocks_library/Scopes,xblocks_library_scopes,g;
s,xblocks_library/Filters,xblocks_library_filters,g;
"

REVERT="
s,xblocks_library_accumulators,xblocks_library/Accumulators,g;
s,xblocks_library_communications,xblocks_library/Communications,g;
s,xblocks_library_correlator,xblocks_library/Correlator,g;
s,xblocks_library_delays,xblocks_library/Delays,g;
s,xblocks_library_downconverter,xblocks_library/Downconverter,g;
s,xblocks_library_ffts_twiddle_coeff_gen,xblocks_library/FFTs/Twiddle/coeff_gen,g;
s,xblocks_library_ffts_twiddle,xblocks_library/FFTs/Twiddle,g;
s,xblocks_library_ffts,xblocks_library/FFTs,g;
s,xblocks_library_flow_control,xblocks_library/Flow_Control,g;
s,xblocks_library_misc,xblocks_library/Misc,g;
s,xblocks_library_multipliers,xblocks_library/Multipliers,g;
s,xblocks_library_pfbs,xblocks_library/PFBs,g;
s,xblocks_library_reorder,xblocks_library/Reorder,g;
s,xblocks_library_scopes,xblocks_library/Scopes,g;
s,xblocks_library_filters,xblocks_library/Filters,g;
"

if [ "${1}" == "-r" ]
then
  action="reverting"
  grep_pattern="xblocks_library_"
  sed_pattern="${REVERT}"
  shift
else
  action="updating"
  grep_pattern="xblocks_library/"
  sed_pattern="${UPDATE}"
fi

for m in "$@"
do
  if ! [ -e "$m" ]
  then
    echo "$m not found"
    continue
  fi
  if ! grep -q "${grep_pattern}" "$m"
  then
    echo "$m modification not needed"
    continue
  fi
  echo -n "${action} librefs in $m..."
  mv "$m" "$m.$$.bak"
  sed -e "${sed_pattern}" "$m.$$.bak" > "$m"
  rm "$m.$$.bak"
  echo ok
done
