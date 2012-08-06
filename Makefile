TARGET=radiotag-api-proposal-v1.00d5
SOURCES=src/$(TARGET).md template/default.html html/style.css
html/$(TARGET).html: $(SOURCES)
	pandoc -c style.css --template template/default.html -s --toc src/$(TARGET).md -o html/$(TARGET).html

html/style.css: css/style.css
	cp css/style.css html/

clean:
	rm html/*
