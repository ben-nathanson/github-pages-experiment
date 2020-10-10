#!/bin/bash
grep -r http: ./*.md &> /dev/null
exit_code=$?
if [ $exit_code -eq 0 ]; then
    echo "Mixed HTTP check failed!"
    echo -e "\nDetails:"
    grep -r http: ./*.md
    exit 1
else
    echo "Mixed HTTP check passed!"
    exit 0
fi