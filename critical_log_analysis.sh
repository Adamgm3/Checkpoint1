# Using grep to read the file and find any critical lines
filtered_lines=$(grep -iE "ERROR|CRITICAL|FATAL" sys_log.txt)

# Passing result through filter pipeline and storing it as a variable
token_pipeline() {
echo "$filtered_lines" | tr '[:space:]' '\n' | sed 's/[^a-zA-Z0-9]//g' | grep -v '^$'
}

tokens=$(token_pipeline)

# Sorting tokens and displaying as readable text
echo "$tokens" | sort | uniq -c | sort -rn | head -10 > top10_critical.txt

# Making file was created
cat top10_critical.txt

echo "Results saved to top10_critical.txt"