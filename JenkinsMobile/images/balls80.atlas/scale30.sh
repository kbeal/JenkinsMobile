for file in `ls *.png`
do
name=`echo $file | cut -f1 -d.`
convert -geometry 30x30 -quality 100 $file ../balls30.atlas/${name}.png
done
