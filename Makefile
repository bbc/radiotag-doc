html/radiotag-api-proposal-v1.00d4.html: src/radiotag-api-proposal-v1.00d4.md template/default.html
	pandoc --template template/default.html -s --toc src/radiotag-api-proposal-v1.00d4.md -o html/radiotag-api-proposal-v1.00d4.html

clean:
	rm html/*.html
