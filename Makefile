build/Release/YAS.app/Contents/MacOS/yas: yas/yas.swift
	xcodebuild

.PHONY: run
run: build/Release/YAS.app/Contents/MacOS/yas
	open build/Release/YAS.app
