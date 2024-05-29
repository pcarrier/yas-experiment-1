build/Release/yas.app/Contents/MacOS/yas: yas/yas.swift
	xcodebuild

.PHONY: run
run: build/Release/yas.app/Contents/MacOS/yas
	open build/Release/yas.app
