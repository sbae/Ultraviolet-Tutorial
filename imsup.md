1. Create a directory in your home directory (`~/`). Let's name it `imsup` for now.
2. Go to `~/imsup`. That's your "working directory". Your code and your results will live here.
3. Download [`imsup_srtr_v5.do`](https://github.com/sbae/Ultraviolet-Tutorial/blob/main/imsup_srtr_v5.do) and upload it to `~/imsup`. Open the file.
4. You'll see on line 20 that I tell stata where the srtr files are, and I refer to them later (line 23).
5. After the data manipulation, I save the file (e.g., line 52 or 125). Unless I specify a directory, it will try to save it in the current working directory by default.
6. Your turn: Try to run the sample script and see if it produces 'imsup_all_2405.dta'. Does it work?
