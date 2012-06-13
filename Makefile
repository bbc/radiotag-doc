html/radiotag-api-proposal-v1.00d4.html: src/radiotag-api-proposal-v1.00d4.md template/default.html html/style.css
	pandoc -c style.css --template template/default.html -s --toc src/radiotag-api-proposal-v1.00d4.md -o html/radiotag-api-proposal-v1.00d4.html

html/style.css: css/style.css
	cp css/style.css html/

clean:
	rm html/*.html
