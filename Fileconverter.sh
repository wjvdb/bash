#!/bin/bash

# Function to convert Markdown to PDF
md_to_pdf() {
	if [ "$#" -ne 2 ]; then
		echo "Usage: md_to_pdf <input.md> <output.pdf>"
		return 1
	fi
	pandoc "$1" -o "$2"
	echo "Converted $1 to $2"
}

# Function to convert PDF to Markdown
pdf_to_md() {
	if [ "$#" -ne 2 ]; then
		echo "Usage: pdf_to_md <input.pdf> <output.md>"
		return 1
	fi
	pdf2md "$1" "$2"
	echo "Converted $1 to $2"
}

# Aliases for convenience
alias md2pdf='md_to_pdf'
alias pdf2md='pdf_to_md'

