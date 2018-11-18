# ymd must be passed with -e "ymd='xxxx'"

# Scale font and line width (dpi) by changing the size!
#  It will always display stretched.
set terminal svg size 700,300 enhanced fname 'arial'  fsize 10 butt solid

csvSmallFile = 'raw/'.ymd.'-small.csv'
csvBigFile = 'raw/'.ymd.'-big.csv'
svgFile = 'plots/'.ymd.'.svg'

set title ymd offset 0,-4 font 'arial,18'
set output svgFile
set datafile separator ";"

set yrange [0:3000]

set key left top

# X-axis is given in seconds since epoch. Format as hour:min.
set xdata time
set timefmt "%s"
set format x "%H:%M"

# Use grid so don't show tics at top or right
set grid
set xtics nomirror
set ytics nomirror

set multiplot

plot csvSmallFile every ::3 using 1:5 title 'CO_2 Small' with lines, \
     csvBigFile   every ::3 using 1:5 title 'CO_2 Big'   with lines
