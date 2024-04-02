# Lua Properties

Read Java Properties in Lua. Because i like Java Properties and i like Lua.

Made by hibi. this project is licensed under MIT.

### Using

If you just want a table that's compatible with Java's Properties, then you
should use `Properties.lua`.

If you want to read a Properties file, then you should use
`PropertiesReader.lua`. It depends on `Properties.lua`.

Check `test.lua` for a practical example.

If you want to test against Java's implementation, run `test.sh`. It requires
`jshell`, `lua`, and `diff` to be in your PATH.
