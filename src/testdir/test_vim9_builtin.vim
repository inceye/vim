" Test using builtin functions in the Vim9 script language.

source check.vim
source vim9.vim

" Test for passing too many or too few arguments to builtin functions
func Test_internalfunc_arg_error()
  let l =<< trim END
    def! FArgErr(): float
      return ceil(1.1, 2)
    enddef
    defcompile
  END
  call writefile(l, 'Xinvalidarg')
  call assert_fails('so Xinvalidarg', 'E118:', '', 1, 'FArgErr')
  let l =<< trim END
    def! FArgErr(): float
      return ceil()
    enddef
    defcompile
  END
  call writefile(l, 'Xinvalidarg')
  call assert_fails('so Xinvalidarg', 'E119:', '', 1, 'FArgErr')
  call delete('Xinvalidarg')
endfunc

" Test for builtin functions returning different types
func Test_InternalFuncRetType()
  let lines =<< trim END
    def RetFloat(): float
      return ceil(1.456)
    enddef

    def RetListAny(): list<any>
      return items({k: 'v'})
    enddef

    def RetListString(): list<string>
      return split('a:b:c', ':')
    enddef

    def RetListDictAny(): list<dict<any>>
      return getbufinfo()
    enddef

    def RetDictNumber(): dict<number>
      return wordcount()
    enddef

    def RetDictString(): dict<string>
      return environ()
    enddef
  END
  call writefile(lines, 'Xscript')
  source Xscript

  call RetFloat()->assert_equal(2.0)
  call RetListAny()->assert_equal([['k', 'v']])
  call RetListString()->assert_equal(['a', 'b', 'c'])
  call RetListDictAny()->assert_notequal([])
  call RetDictNumber()->assert_notequal({})
  call RetDictString()->assert_notequal({})
  call delete('Xscript')
endfunc

def Test_abs()
  assert_equal(0, abs(0))
  assert_equal(2, abs(-2))
  assert_equal(3, abs(3))
  CheckDefAndScriptFailure2(['abs("text")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  if has('float')
    assert_equal(0, abs(0))
    assert_equal(2.0, abs(-2.0))
    assert_equal(3.0, abs(3.0))
  endif
enddef

def Test_add()
  CheckDefAndScriptFailure2(['add({}, 1)'], 'E1013: Argument 1: type mismatch, expected list<any> but got dict<unknown>', 'E1226: String or List required for argument 1')
  CheckDefFailure(['add([1], "a")'], 'E1012: Type mismatch; expected number but got string')
enddef

def Test_add_blob()
  var b1: blob = 0z12
  add(b1, 0x34)
  assert_equal(0z1234, b1)

  var b2: blob # defaults to empty blob
  add(b2, 0x67)
  assert_equal(0z67, b2)

  var lines =<< trim END
      var b: blob
      add(b, "x")
  END
  CheckDefFailure(lines, 'E1012:', 2)

  lines =<< trim END
      add(test_null_blob(), 123)
  END
  CheckDefExecAndScriptFailure(lines, 'E1131:', 1)

  lines =<< trim END
      var b: blob = test_null_blob()
      add(b, 123)
  END
  CheckDefExecFailure(lines, 'E1131:', 2)

  # Getting variable with NULL blob allocates a new blob at script level
  lines =<< trim END
      vim9script
      var b: blob = test_null_blob()
      add(b, 123)
  END
  CheckScriptSuccess(lines)
enddef

def Test_add_list()
  var l: list<number>  # defaults to empty list
  add(l, 9)
  assert_equal([9], l)

  var lines =<< trim END
      var l: list<number>
      add(l, "x")
  END
  CheckDefFailure(lines, 'E1012:', 2)

  lines =<< trim END
      add(test_null_list(), 123)
  END
  CheckDefExecAndScriptFailure(lines, 'E1130:', 1)

  lines =<< trim END
      var l: list<number> = test_null_list()
      add(l, 123)
  END
  CheckDefExecFailure(lines, 'E1130:', 2)

  # Getting variable with NULL list allocates a new list at script level
  lines =<< trim END
      vim9script
      var l: list<number> = test_null_list()
      add(l, 123)
  END
  CheckScriptSuccess(lines)

  lines =<< trim END
      vim9script
      var l: list<string> = ['a']
      l->add(123)
  END
  CheckScriptFailure(lines, 'E1012: Type mismatch; expected string but got number', 3)

  lines =<< trim END
      vim9script
      var l: list<string>
      l->add(123)
  END
  CheckScriptFailure(lines, 'E1012: Type mismatch; expected string but got number', 3)
enddef

def Test_and()
  CheckDefAndScriptFailure2(['and("x", 0x2)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['and(0x1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_append()
  new
  setline(1, range(3))
  var res1: number = append(1, 'one')
  assert_equal(0, res1)
  var res2: bool = append(3, 'two')
  assert_equal(false, res2)
  assert_equal(['0', 'one', '1', 'two', '2'], getline(1, 6))

  append(0, 'zero')
  assert_equal('zero', getline(1))
  append(0, {a: 10})
  assert_equal("{'a': 10}", getline(1))
  append(0, function('min'))
  assert_equal("function('min')", getline(1))
  CheckDefAndScriptFailure2(['append([1], "x")'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1220: String or Number required for argument 1')
  bwipe!
enddef

def Test_appendbufline()
  new
  var bnum: number = bufnr()
  :wincmd w
  appendbufline(bnum, 0, range(3))
  var res1: number = appendbufline(bnum, 1, 'one')
  assert_equal(0, res1)
  var res2: bool = appendbufline(bnum, 3, 'two')
  assert_equal(false, res2)
  assert_equal(['0', 'one', '1', 'two', '2', ''], getbufline(bnum, 1, '$'))
  appendbufline(bnum, 0, 'zero')
  assert_equal(['zero'], getbufline(bnum, 1))
  CheckDefAndScriptFailure2(['appendbufline([1], 1, "x")'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['appendbufline(1, [1], "x")'], 'E1013: Argument 2: type mismatch, expected string but got list<number>', 'E1220: String or Number required for argument 2')
  CheckDefAndScriptFailure2(['appendbufline(1, 1, {"a": 10})'], 'E1013: Argument 3: type mismatch, expected string but got dict<number>', 'E1224: String or List required for argument 3')
  bnum->bufwinid()->win_gotoid()
  bwipe!
enddef

def Test_argc()
  CheckDefAndScriptFailure2(['argc("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_arglistid()
  CheckDefAndScriptFailure2(['arglistid("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['arglistid(1, "y")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['arglistid("x", "y")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_argv()
  CheckDefAndScriptFailure2(['argv("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['argv(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['argv("x", "y")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_assert_beeps()
  CheckDefAndScriptFailure2(['assert_beeps(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
enddef

def Test_assert_equalfile()
  CheckDefAndScriptFailure2(['assert_equalfile(1, "f2")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['assert_equalfile("f1", true)'], 'E1013: Argument 2: type mismatch, expected string but got bool', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['assert_equalfile("f1", "f2", ["a"])'], 'E1013: Argument 3: type mismatch, expected string but got list<string>', 'E1174: String required for argument 3')
enddef

def Test_assert_exception()
  CheckDefAndScriptFailure2(['assert_exception({})'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['assert_exception("E1:", v:null)'], 'E1013: Argument 2: type mismatch, expected string but got special', 'E1174: String required for argument 2')
enddef

def Test_assert_fails()
  CheckDefAndScriptFailure2(['assert_fails([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['assert_fails("a", true)'], 'E1013: Argument 2: type mismatch, expected string but got bool', 'E1222: String or List required for argument 2')
  CheckDefAndScriptFailure2(['assert_fails("a", "b", "c", "d")'], 'E1013: Argument 4: type mismatch, expected number but got string', 'E1210: Number required for argument 4')
  CheckDefAndScriptFailure2(['assert_fails("a", "b", "c", 4, 5)'], 'E1013: Argument 5: type mismatch, expected string but got number', 'E1174: String required for argument 5')
enddef

def Test_assert_inrange()
  CheckDefAndScriptFailure2(['assert_inrange("a", 2, 3)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  CheckDefAndScriptFailure2(['assert_inrange(1, "b", 3)'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 2')
  CheckDefAndScriptFailure2(['assert_inrange(1, 2, "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 3')
  CheckDefAndScriptFailure2(['assert_inrange(1, 2, 3, 4)'], 'E1013: Argument 4: type mismatch, expected string but got number', 'E1174: String required for argument 4')
enddef

def Test_assert_match()
  CheckDefAndScriptFailure2(['assert_match({}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>', '')
  CheckDefAndScriptFailure2(['assert_match("a", 1)'], 'E1013: Argument 2: type mismatch, expected string but got number', '')
  CheckDefAndScriptFailure2(['assert_match("a", "b", null)'], 'E1013: Argument 3: type mismatch, expected string but got special', '')
enddef

def Test_assert_nobeep()
  CheckDefAndScriptFailure2(['assert_nobeep(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
enddef

def Test_assert_notmatch()
  CheckDefAndScriptFailure2(['assert_notmatch({}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>', '')
  CheckDefAndScriptFailure2(['assert_notmatch("a", 1)'], 'E1013: Argument 2: type mismatch, expected string but got number', '')
  CheckDefAndScriptFailure2(['assert_notmatch("a", "b", null)'], 'E1013: Argument 3: type mismatch, expected string but got special', '')
enddef

def Test_assert_report()
  CheckDefAndScriptFailure2(['assert_report([1, 2])'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1174: String required for argument 1')
enddef

def Test_balloon_show()
  CheckGui
  CheckFeature balloon_eval

  assert_fails('balloon_show(10)', 'E1222:')
  assert_fails('balloon_show(true)', 'E1222:')

  CheckDefAndScriptFailure2(['balloon_show(1.2)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E1222: String or List required for argument 1')
  CheckDefAndScriptFailure2(['balloon_show({"a": 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1222: String or List required for argument 1')
enddef

def Test_balloon_split()
  CheckFeature balloon_eval_term

  assert_fails('balloon_split([])', 'E1174:')
  assert_fails('balloon_split(true)', 'E1174:')
enddef

def Test_browse()
  CheckFeature browse

  CheckDefAndScriptFailure2(['browse(2, "title", "dir", "file")'], 'E1013: Argument 1: type mismatch, expected bool but got number', 'E1212: Bool required for argument 1')
  CheckDefAndScriptFailure2(['browse(true, 2, "dir", "file")'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['browse(true, "title", 3, "file")'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E1174: String required for argument 3')
  CheckDefAndScriptFailure2(['browse(true, "title", "dir", 4)'], 'E1013: Argument 4: type mismatch, expected string but got number', 'E1174: String required for argument 4')
enddef

def Test_browsedir()
  if has('browse')
    CheckDefAndScriptFailure2(['browsedir({}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>', 'E1174: String required for argument 1')
    CheckDefAndScriptFailure2(['browsedir("a", [])'], 'E1013: Argument 2: type mismatch, expected string but got list<unknown>', 'E1174: String required for argument 2')
  endif
enddef

def Test_bufadd()
  assert_fails('bufadd([])', 'E1174:')
enddef

def Test_bufexists()
  assert_fails('bufexists(true)', 'E1220:')
enddef

def Test_buflisted()
  var res: bool = buflisted('asdf')
  assert_equal(false, res)
  assert_fails('buflisted(true)', 'E1220:')
  assert_fails('buflisted([])', 'E1220:')
enddef

def Test_bufload()
  assert_fails('bufload([])', 'E1220:')
enddef

def Test_bufloaded()
  assert_fails('bufloaded(true)', 'E1220:')
  assert_fails('bufloaded([])', 'E1220:')
enddef

def Test_bufname()
  split SomeFile
  bufname('%')->assert_equal('SomeFile')
  edit OtherFile
  bufname('#')->assert_equal('SomeFile')
  close
  assert_fails('bufname(true)', 'E1220:')
  assert_fails('bufname([])', 'E1220:')
enddef

def Test_bufnr()
  var buf = bufnr()
  bufnr('%')->assert_equal(buf)

  buf = bufnr('Xdummy', true)
  buf->assert_notequal(-1)
  exe 'bwipe! ' .. buf
  CheckDefAndScriptFailure2(['bufnr([1])'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['bufnr(1, 2)'], 'E1013: Argument 2: type mismatch, expected bool but got number', 'E1212: Bool required for argument 2')
enddef

def Test_bufwinid()
  var origwin = win_getid()
  below split SomeFile
  var SomeFileID = win_getid()
  below split OtherFile
  below split SomeFile
  bufwinid('SomeFile')->assert_equal(SomeFileID)

  win_gotoid(origwin)
  only
  bwipe SomeFile
  bwipe OtherFile

  assert_fails('bufwinid(true)', 'E1220:')
  assert_fails('bufwinid([])', 'E1220:')
enddef

def Test_bufwinnr()
  assert_fails('bufwinnr(true)', 'E1220:')
  assert_fails('bufwinnr([])', 'E1220:')
enddef

def Test_byte2line()
  CheckDefAndScriptFailure2(['byte2line("1")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['byte2line([])'], 'E1013: Argument 1: type mismatch, expected number but got list<unknown>', 'E1210: Number required for argument 1')
  assert_equal(-1, byte2line(0))
enddef

def Test_byteidx()
  CheckDefAndScriptFailure2(['byteidx(1, 2)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['byteidx("a", "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_byteidxcomp()
  CheckDefAndScriptFailure2(['byteidxcomp(1, 2)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['byteidxcomp("a", "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_call_call()
  var l = [3, 2, 1]
  call('reverse', [l])
  l->assert_equal([1, 2, 3])
  CheckDefAndScriptFailure2(['call("reverse", 2)'], 'E1013: Argument 2: type mismatch, expected list<any> but got number', 'E1211: List required for argument 2')
  CheckDefAndScriptFailure2(['call("reverse", [2], [1])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 3')
enddef

def Test_ch_canread()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['ch_canread(10)'], 'E1013: Argument 1: type mismatch, expected channel but got number', 'E1217: Channel or Job required for argument 1')
  endif
enddef

def Test_ch_close()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['ch_close("c")'], 'E1013: Argument 1: type mismatch, expected channel but got string', 'E1217: Channel or Job required for argument 1')
  endif
enddef

def Test_ch_close_in()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['ch_close_in(true)'], 'E1013: Argument 1: type mismatch, expected channel but got bool', 'E1217: Channel or Job required for argument 1')
  endif
enddef

def Test_ch_evalexpr()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['ch_evalexpr(1, "a")'], 'E1013: Argument 1: type mismatch, expected channel but got number', 'E1217: Channel or Job required for argument 1')
    CheckDefAndScriptFailure2(['ch_evalexpr(test_null_channel(), 1, [])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 3')
  endif
enddef

def Test_ch_evalraw()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['ch_evalraw(1, "")'], 'E1013: Argument 1: type mismatch, expected channel but got number', 'E1217: Channel or Job required for argument 1')
    CheckDefAndScriptFailure2(['ch_evalraw(test_null_channel(), 1)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1221: String or Blob required for argument 2')
    CheckDefAndScriptFailure2(['ch_evalraw(test_null_channel(), "", [])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 3')
  endif
enddef

def Test_ch_getbufnr()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['ch_getbufnr(1, "a")'], 'E1013: Argument 1: type mismatch, expected channel but got number', 'E1217: Channel or Job required for argument 1')
    CheckDefAndScriptFailure2(['ch_getbufnr(test_null_channel(), 1)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  endif
enddef

def Test_ch_getjob()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['ch_getjob(1)'], 'E1013: Argument 1: type mismatch, expected channel but got number', 'E1217: Channel or Job required for argument 1')
    CheckDefAndScriptFailure2(['ch_getjob({"a": 10})'], 'E1013: Argument 1: type mismatch, expected channel but got dict<number>', 'E1217: Channel or Job required for argument 1')
    assert_equal(0, ch_getjob(test_null_channel()))
  endif
enddef

def Test_ch_info()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['ch_info([1])'], 'E1013: Argument 1: type mismatch, expected channel but got list<number>', 'E1217: Channel or Job required for argument 1')
  endif
enddef

def Test_ch_log()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['ch_log(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1174: String required for argument 1')
    CheckDefAndScriptFailure2(['ch_log("a", 1)'], 'E1013: Argument 2: type mismatch, expected channel but got number', 'E1217: Channel or Job required for argument 2')
  endif
enddef

def Test_ch_logfile()
  if !has('channel')
    CheckFeature channel
  else
    assert_fails('ch_logfile(true)', 'E1174:')
    assert_fails('ch_logfile("foo", true)', 'E1174:')

    CheckDefAndScriptFailure2(['ch_logfile(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
    CheckDefAndScriptFailure2(['ch_logfile("a", true)'], 'E1013: Argument 2: type mismatch, expected string but got bool', 'E1174: String required for argument 2')
  endif
enddef

def Test_ch_open()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['ch_open({"a": 10}, "a")'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1174: String required for argument 1')
    CheckDefAndScriptFailure2(['ch_open("a", [1])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 2')
  endif
enddef

def Test_ch_read()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['ch_read(1)'], 'E1013: Argument 1: type mismatch, expected channel but got number', 'E1217: Channel or Job required for argument 1')
    CheckDefAndScriptFailure2(['ch_read(test_null_channel(), [])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 2')
  endif
enddef

def Test_ch_readblob()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['ch_readblob(1)'], 'E1013: Argument 1: type mismatch, expected channel but got number', 'E1217: Channel or Job required for argument 1')
    CheckDefAndScriptFailure2(['ch_readblob(test_null_channel(), [])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 2')
  endif
enddef

def Test_ch_readraw()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['ch_readraw(1)'], 'E1013: Argument 1: type mismatch, expected channel but got number', 'E1217: Channel or Job required for argument 1')
    CheckDefAndScriptFailure2(['ch_readraw(test_null_channel(), [])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 2')
  endif
enddef

def Test_ch_sendexpr()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['ch_sendexpr(1, "a")'], 'E1013: Argument 1: type mismatch, expected channel but got number', 'E1217: Channel or Job required for argument 1')
    CheckDefAndScriptFailure2(['ch_sendexpr(test_null_channel(), 1, [])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 3')
  endif
enddef

def Test_ch_sendraw()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['ch_sendraw(1, "")'], 'E1013: Argument 1: type mismatch, expected channel but got number', 'E1217: Channel or Job required for argument 1')
    CheckDefAndScriptFailure2(['ch_sendraw(test_null_channel(), 1)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1221: String or Blob required for argument 2')
    CheckDefAndScriptFailure2(['ch_sendraw(test_null_channel(), "", [])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 3')
  endif
enddef

def Test_ch_setoptions()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['ch_setoptions(1, {})'], 'E1013: Argument 1: type mismatch, expected channel but got number', 'E1217: Channel or Job required for argument 1')
    CheckDefAndScriptFailure2(['ch_setoptions(test_null_channel(), [])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 2')
  endif
enddef

def Test_ch_status()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['ch_status(1)'], 'E1013: Argument 1: type mismatch, expected channel but got number', 'E1217: Channel or Job required for argument 1')
    CheckDefAndScriptFailure2(['ch_status(test_null_channel(), [])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 2')
  endif
enddef

def Test_char2nr()
  char2nr('あ', true)->assert_equal(12354)

  assert_fails('char2nr(true)', 'E1174:')
  CheckDefAndScriptFailure2(['char2nr(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['char2nr("a", 2)'], 'E1013: Argument 2: type mismatch, expected bool but got number', 'E1212: Bool required for argument 2')
  assert_equal(97, char2nr('a', 1))
  assert_equal(97, char2nr('a', 0))
  assert_equal(97, char2nr('a', true))
  assert_equal(97, char2nr('a', false))
enddef

def Test_charclass()
  assert_fails('charclass(true)', 'E1174:')
enddef

def Test_charcol()
  CheckDefAndScriptFailure2(['charcol(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1222: String or List required for argument 1')
  CheckDefAndScriptFailure2(['charcol({a: 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1222: String or List required for argument 1')
  new
  setline(1, ['abcdefgh'])
  cursor(1, 4)
  assert_equal(4, charcol('.'))
  assert_equal(9, charcol([1, '$']))
  assert_equal(0, charcol([10, '$']))
  bw!
enddef

def Test_charidx()
  CheckDefAndScriptFailure2(['charidx(0z10, 1)'], 'E1013: Argument 1: type mismatch, expected string but got blob', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['charidx("a", "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['charidx("a", 1, "")'], 'E1013: Argument 3: type mismatch, expected bool but got string', 'E1212: Bool required for argument 3')
enddef

def Test_chdir()
  assert_fails('chdir(true)', 'E1174:')
enddef

def Test_cindent()
  CheckDefAndScriptFailure2(['cindent([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['cindent(null)'], 'E1013: Argument 1: type mismatch, expected string but got special', 'E1220: String or Number required for argument 1')
  assert_equal(-1, cindent(0))
  assert_equal(0, cindent('.'))
enddef

def Test_clearmatches()
  CheckDefAndScriptFailure2(['clearmatches("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_col()
  new
  setline(1, 'abcdefgh')
  cursor(1, 4)
  assert_equal(4, col('.'))
  col([1, '$'])->assert_equal(9)
  assert_equal(0, col([10, '$']))

  assert_fails('col(true)', 'E1222:')

  CheckDefAndScriptFailure2(['col(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1222: String or List required for argument 1')
  CheckDefAndScriptFailure2(['col({a: 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1222: String or List required for argument 1')
  CheckDefAndScriptFailure2(['col(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1222: String or List required for argument 1')
  bw!
enddef

def Test_complete()
  CheckDefAndScriptFailure2(['complete("1", [])'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['complete(1, {})'], 'E1013: Argument 2: type mismatch, expected list<any> but got dict<unknown>', 'E1211: List required for argument 2')
enddef

def Test_complete_add()
  CheckDefAndScriptFailure2(['complete_add([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1223: String or List required for argument 1')
enddef

def Test_complete_info()
  CheckDefAndScriptFailure2(['complete_info("")'], 'E1013: Argument 1: type mismatch, expected list<string> but got string', 'E1211: List required for argument 1')
  CheckDefAndScriptFailure2(['complete_info({})'], 'E1013: Argument 1: type mismatch, expected list<string> but got dict<unknown>', 'E1211: List required for argument 1')
  assert_equal({'pum_visible': 0, 'mode': '', 'selected': -1, 'items': []}, complete_info())
  assert_equal({'mode': '', 'items': []}, complete_info(['mode', 'items']))
enddef

def Test_confirm()
  if !has('dialog_con') && !has('dialog_gui')
    CheckFeature dialog_con
  endif

  assert_fails('confirm(true)', 'E1174:')
  assert_fails('confirm("yes", true)', 'E1174:')
  assert_fails('confirm("yes", "maybe", 2, true)', 'E1174:')
  CheckDefAndScriptFailure2(['confirm(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['confirm("a", 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['confirm("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  CheckDefAndScriptFailure2(['confirm("a", "b", 3, 4)'], 'E1013: Argument 4: type mismatch, expected string but got number', 'E1174: String required for argument 4')
enddef

def Test_copy_return_type()
  var l = copy([1, 2, 3])
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(6)

  var dl = deepcopy([1, 2, 3])
  res = 0
  for n in dl
    res += n
  endfor
  res->assert_equal(6)

  dl = deepcopy([1, 2, 3], true)
enddef

def Test_count()
  count('ABC ABC ABC', 'b', true)->assert_equal(3)
  count('ABC ABC ABC', 'b', false)->assert_equal(0)
  CheckDefAndScriptFailure2(['count(10, 1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1225: String or List required for argument 1')
  CheckDefAndScriptFailure2(['count("a", [1], 2)'], 'E1013: Argument 3: type mismatch, expected bool but got number', 'E1212: Bool required for argument 3')
  CheckDefAndScriptFailure2(['count("a", [1], 0, "b")'], 'E1013: Argument 4: type mismatch, expected number but got string', 'E1210: Number required for argument 4')
  count([1, 2, 2, 3], 2)->assert_equal(2)
  count([1, 2, 2, 3], 2, false, 2)->assert_equal(1)
  count({a: 1.1, b: 2.2, c: 1.1}, 1.1)->assert_equal(2)
enddef

def Test_cscope_connection()
  CheckFeature cscope
  assert_equal(0, cscope_connection())
  CheckDefAndScriptFailure2(['cscope_connection("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['cscope_connection(1, 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['cscope_connection(1, "b", 3)'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E1174: String required for argument 3')
enddef

def Test_cursor()
  new
  setline(1, range(4))
  cursor(2, 1)
  assert_equal(2, getcurpos()[1])
  cursor('$', 1)
  assert_equal(4, getcurpos()[1])
  cursor([2, 1])
  assert_equal(2, getcurpos()[1])

  var lines =<< trim END
    cursor('2', 1)
  END
  CheckDefExecAndScriptFailure(lines, 'E1209:')
  CheckDefAndScriptFailure2(['cursor(0z10, 1)'], 'E1013: Argument 1: type mismatch, expected number but got blob', 'E1224: String or List required for argument 1')
  CheckDefAndScriptFailure2(['cursor(1, "2")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['cursor(1, 2, "3")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
enddef

def Test_debugbreak()
  CheckMSWindows
  CheckDefAndScriptFailure2(['debugbreak("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_deepcopy()
  CheckDefAndScriptFailure2(['deepcopy({}, 2)'], 'E1013: Argument 2: type mismatch, expected bool but got number', 'E1212: Bool required for argument 2')
enddef

def Test_delete()
  var res: bool = delete('doesnotexist')
  assert_equal(true, res)

  CheckDefAndScriptFailure2(['delete(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['delete("a", 10)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
enddef

def Test_deletebufline()
  CheckDefAndScriptFailure2(['deletebufline([], 2)'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['deletebufline("a", [])'], 'E1013: Argument 2: type mismatch, expected string but got list<unknown>', 'E1220: String or Number required for argument 2')
  CheckDefAndScriptFailure2(['deletebufline("a", 2, 0z10)'], 'E1013: Argument 3: type mismatch, expected string but got blob', 'E1220: String or Number required for argument 3')
enddef

def Test_diff_filler()
  CheckDefAndScriptFailure2(['diff_filler([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['diff_filler(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1220: String or Number required for argument 1')
  assert_equal(0, diff_filler(1))
  assert_equal(0, diff_filler('.'))
enddef

def Test_diff_hlID()
  CheckDefAndScriptFailure2(['diff_hlID(0z10, 1)'], 'E1013: Argument 1: type mismatch, expected string but got blob', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['diff_hlID(1, "a")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_echoraw()
  CheckDefAndScriptFailure2(['echoraw(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['echoraw(["x"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E1174: String required for argument 1')
enddef

def Test_escape()
  CheckDefAndScriptFailure2(['escape(10, " ")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['escape(true, false)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['escape("a", 10)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  assert_equal('a\:b', escape("a:b", ":"))
enddef

def Test_eval()
  CheckDefAndScriptFailure2(['eval(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['eval(null)'], 'E1013: Argument 1: type mismatch, expected string but got special', 'E1174: String required for argument 1')
  assert_equal(2, eval('1 + 1'))
enddef

def Test_executable()
  assert_false(executable(""))
  assert_false(executable(test_null_string()))

  CheckDefExecFailure(['echo executable(123)'], 'E1013:')
  CheckDefExecFailure(['echo executable(true)'], 'E1013:')
enddef

def Test_execute()
  var res = execute("echo 'hello'")
  assert_equal("\nhello", res)
  res = execute(["echo 'here'", "echo 'there'"])
  assert_equal("\nhere\nthere", res)

  CheckDefAndScriptFailure2(['execute(123)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1222: String or List required for argument 1')
  CheckDefFailure(['execute([123])'], 'E1013: Argument 1: type mismatch, expected list<string> but got list<number>')
  CheckDefExecFailure(['echo execute(["xx", 123])'], 'E492')
  CheckDefAndScriptFailure2(['execute("xx", 123)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
enddef

def Test_exepath()
  CheckDefExecFailure(['echo exepath(true)'], 'E1013:')
  CheckDefExecFailure(['echo exepath(v:null)'], 'E1013:')
  CheckDefExecFailure(['echo exepath("")'], 'E1175:')
enddef

def Test_exists()
  CheckDefAndScriptFailure2(['exists(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  call assert_equal(1, exists('&tabstop'))
enddef

def Test_expand()
  split SomeFile
  expand('%', true, true)->assert_equal(['SomeFile'])
  close
  CheckDefAndScriptFailure2(['expand(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['expand("a", 2)'], 'E1013: Argument 2: type mismatch, expected bool but got number', 'E1212: Bool required for argument 2')
  CheckDefAndScriptFailure2(['expand("a", true, 2)'], 'E1013: Argument 3: type mismatch, expected bool but got number', 'E1212: Bool required for argument 3')
enddef

def Test_expandcmd()
  $FOO = "blue"
  assert_equal("blue sky", expandcmd("`=$FOO .. ' sky'`"))

  assert_equal("yes", expandcmd("`={a: 'yes'}['a']`"))
enddef

def Test_extend_arg_types()
  g:number_one = 1
  g:string_keep = 'keep'
  var lines =<< trim END
      assert_equal([1, 2, 3], extend([1, 2], [3]))
      assert_equal([3, 1, 2], extend([1, 2], [3], 0))
      assert_equal([1, 3, 2], extend([1, 2], [3], 1))
      assert_equal([1, 3, 2], extend([1, 2], [3], g:number_one))

      assert_equal({a: 1, b: 2, c: 3}, extend({a: 1, b: 2}, {c: 3}))
      assert_equal({a: 1, b: 4}, extend({a: 1, b: 2}, {b: 4}))
      assert_equal({a: 1, b: 2}, extend({a: 1, b: 2}, {b: 4}, 'keep'))
      assert_equal({a: 1, b: 2}, extend({a: 1, b: 2}, {b: 4}, g:string_keep))

      var res: list<dict<any>>
      extend(res, mapnew([1, 2], (_, v) => ({})))
      assert_equal([{}, {}], res)
  END
  CheckDefAndScriptSuccess(lines)

  CheckDefAndScriptFailure2(['extend("a", 1)'], 'E1013: Argument 1: type mismatch, expected list<any> but got string', 'E712: Argument of extend() must be a List or Dictionary')
  CheckDefAndScriptFailure2(['extend([1, 2], 3)'], 'E1013: Argument 2: type mismatch, expected list<number> but got number', 'E712: Argument of extend() must be a List or Dictionary')
  CheckDefAndScriptFailure2(['extend([1, 2], ["x"])'], 'E1013: Argument 2: type mismatch, expected list<number> but got list<string>', 'E1013: Argument 2: type mismatch, expected list<number> but got list<string>')
  CheckDefFailure(['extend([1, 2], [3], "x")'], 'E1013: Argument 3: type mismatch, expected number but got string')

  CheckDefFailure(['extend({a: 1}, 42)'], 'E1013: Argument 2: type mismatch, expected dict<number> but got number')
  CheckDefFailure(['extend({a: 1}, {b: "x"})'], 'E1013: Argument 2: type mismatch, expected dict<number> but got dict<string>')
  CheckDefFailure(['extend({a: 1}, {b: 2}, 1)'], 'E1013: Argument 3: type mismatch, expected string but got number')

  CheckDefFailure(['extend([1], ["b"])'], 'E1013: Argument 2: type mismatch, expected list<number> but got list<string>')
  CheckDefExecFailure(['extend([1], ["b", 1])'], 'E1013: Argument 2: type mismatch, expected list<number> but got list<any>')

  CheckScriptFailure(['vim9script', 'extend([1], ["b", 1])'], 'E1013: Argument 2: type mismatch, expected list<number> but got list<any> in extend()')
enddef

func g:ExtendDict(d)
  call extend(a:d, #{xx: 'x'})
endfunc

def Test_extend_dict_item_type()
  var lines =<< trim END
       var d: dict<number> = {a: 1}
       extend(d, {b: 2})
  END
  CheckDefAndScriptSuccess(lines)

  lines =<< trim END
       var d: dict<number> = {a: 1}
       extend(d, {b: 'x'})
  END
  CheckDefAndScriptFailure(lines, 'E1013: Argument 2: type mismatch, expected dict<number> but got dict<string>', 2)

  lines =<< trim END
       var d: dict<number> = {a: 1}
       g:ExtendDict(d)
  END
  CheckDefExecFailure(lines, 'E1012: Type mismatch; expected number but got string', 0)
  CheckScriptFailure(['vim9script'] + lines, 'E1012:', 1)
enddef

func g:ExtendList(l)
  call extend(a:l, ['x'])
endfunc

def Test_extend_list_item_type()
  var lines =<< trim END
       var l: list<number> = [1]
       extend(l, [2])
  END
  CheckDefAndScriptSuccess(lines)

  lines =<< trim END
       var l: list<number> = [1]
       extend(l, ['x'])
  END
  CheckDefAndScriptFailure(lines, 'E1013: Argument 2: type mismatch, expected list<number> but got list<string>', 2)

  lines =<< trim END
       var l: list<number> = [1]
       g:ExtendList(l)
  END
  CheckDefExecFailure(lines, 'E1012: Type mismatch; expected number but got string', 0)
  CheckScriptFailure(['vim9script'] + lines, 'E1012:', 1)
enddef

def Test_extend_return_type()
  var l = extend([1, 2], [3])
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(6)
enddef

def Test_extend_with_error_function()
  var lines =<< trim END
      vim9script
      def F()
        {
          var m = 10
        }
        echo m
      enddef

      def Test()
        var d: dict<any> = {}
        d->extend({A: 10, Func: function('F', [])})
      enddef

      Test()
  END
  CheckScriptFailure(lines, 'E1001: Variable not found: m')
enddef

def Test_extendnew()
  assert_equal([1, 2, 'a'], extendnew([1, 2], ['a']))
  assert_equal({one: 1, two: 'a'}, extendnew({one: 1}, {two: 'a'}))

  CheckDefAndScriptFailure2(['extendnew({a: 1}, 42)'], 'E1013: Argument 2: type mismatch, expected dict<number> but got number', 'E712: Argument of extendnew() must be a List or Dictionary')
  CheckDefAndScriptFailure2(['extendnew({a: 1}, [42])'], 'E1013: Argument 2: type mismatch, expected dict<number> but got list<number>', 'E712: Argument of extendnew() must be a List or Dictionary')
  CheckDefAndScriptFailure2(['extendnew([1, 2], "x")'], 'E1013: Argument 2: type mismatch, expected list<number> but got string', 'E712: Argument of extendnew() must be a List or Dictionary')
  CheckDefAndScriptFailure2(['extendnew([1, 2], {x: 1})'], 'E1013: Argument 2: type mismatch, expected list<number> but got dict<number>', 'E712: Argument of extendnew() must be a List or Dictionary')
enddef

def Test_feedkeys()
  CheckDefAndScriptFailure2(['feedkeys(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['feedkeys("x", 10)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['feedkeys([], {})'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1174: String required for argument 1')
  g:TestVar = 1
  feedkeys(":g:TestVar = 789\n", 'xt')
  assert_equal(789, g:TestVar)
  unlet g:TestVar
enddef

def Test_filereadable()
  assert_false(filereadable(""))
  assert_false(filereadable(test_null_string()))

  CheckDefExecFailure(['echo filereadable(123)'], 'E1013:')
  CheckDefExecFailure(['echo filereadable(true)'], 'E1013:')
enddef

def Test_filewritable()
  assert_false(filewritable(""))
  assert_false(filewritable(test_null_string()))

  CheckDefExecFailure(['echo filewritable(123)'], 'E1013:')
  CheckDefExecFailure(['echo filewritable(true)'], 'E1013:')
enddef

def Test_finddir()
  CheckDefAndScriptFailure2(['finddir(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['finddir(v:null)'], 'E1013: Argument 1: type mismatch, expected string but got special', 'E1174: String required for argument 1')
  CheckDefExecFailure(['echo finddir("")'], 'E1175:')
  CheckDefAndScriptFailure2(['finddir("a", [])'], 'E1013: Argument 2: type mismatch, expected string but got list<unknown>', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['finddir("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
enddef

def Test_findfile()
  CheckDefExecFailure(['findfile(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool')
  CheckDefExecFailure(['findfile(v:null)'], 'E1013: Argument 1: type mismatch, expected string but got special')
  CheckDefExecFailure(['findfile("")'], 'E1175:')
  CheckDefAndScriptFailure2(['findfile("a", [])'], 'E1013: Argument 2: type mismatch, expected string but got list<unknown>', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['findfile("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
enddef

def Test_flattennew()
  var lines =<< trim END
      var l = [1, [2, [3, 4]], 5]
      call assert_equal([1, 2, 3, 4, 5], flattennew(l))
      call assert_equal([1, [2, [3, 4]], 5], l)

      call assert_equal([1, 2, [3, 4], 5], flattennew(l, 1))
      call assert_equal([1, [2, [3, 4]], 5], l)
  END
  CheckDefAndScriptSuccess(lines)

  lines =<< trim END
      echo flatten([1, 2, 3])
  END
  CheckDefAndScriptFailure(lines, 'E1158:')
  CheckDefAndScriptFailure2(['flattennew({})'], 'E1013: Argument 1: type mismatch, expected list<any> but got dict<unknown>', 'E1211: List required for argument 1')
  CheckDefAndScriptFailure2(['flattennew([], "1")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

" Test for float functions argument type
def Test_float_funcs_args()
  CheckFeature float

  # acos()
  CheckDefAndScriptFailure2(['acos("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # asin()
  CheckDefAndScriptFailure2(['asin("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # atan()
  CheckDefAndScriptFailure2(['atan("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # atan2()
  CheckDefAndScriptFailure2(['atan2("a", 1.1)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  CheckDefAndScriptFailure2(['atan2(1.2, "a")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 2')
  CheckDefAndScriptFailure2(['atan2(1.2)'], 'E119:', 'E119:')
  # ceil()
  CheckDefAndScriptFailure2(['ceil("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # cos()
  CheckDefAndScriptFailure2(['cos("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # cosh()
  CheckDefAndScriptFailure2(['cosh("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # exp()
  CheckDefAndScriptFailure2(['exp("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # float2nr()
  CheckDefAndScriptFailure2(['float2nr("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # floor()
  CheckDefAndScriptFailure2(['floor("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # fmod()
  CheckDefAndScriptFailure2(['fmod(1.1, "a")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 2')
  CheckDefAndScriptFailure2(['fmod("a", 1.1)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  CheckDefAndScriptFailure2(['fmod(1.1)'], 'E119:', 'E119:')
  # isinf()
  CheckDefAndScriptFailure2(['isinf("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # isnan()
  CheckDefAndScriptFailure2(['isnan("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # log()
  CheckDefAndScriptFailure2(['log("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # log10()
  CheckDefAndScriptFailure2(['log10("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # pow()
  CheckDefAndScriptFailure2(['pow("a", 1.1)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  CheckDefAndScriptFailure2(['pow(1.1, "a")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 2')
  CheckDefAndScriptFailure2(['pow(1.1)'], 'E119:', 'E119:')
  # round()
  CheckDefAndScriptFailure2(['round("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # sin()
  CheckDefAndScriptFailure2(['sin("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # sinh()
  CheckDefAndScriptFailure2(['sinh("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # sqrt()
  CheckDefAndScriptFailure2(['sqrt("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # tan()
  CheckDefAndScriptFailure2(['tan("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # tanh()
  CheckDefAndScriptFailure2(['tanh("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
  # trunc()
  CheckDefAndScriptFailure2(['trunc("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1219: Float or Number required for argument 1')
enddef

def Test_fnameescape()
  CheckDefAndScriptFailure2(['fnameescape(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  assert_equal('\+a\%b\|', fnameescape('+a%b|'))
enddef

def Test_fnamemodify()
  CheckDefSuccess(['echo fnamemodify(test_null_string(), ":p")'])
  CheckDefSuccess(['echo fnamemodify("", ":p")'])
  CheckDefSuccess(['echo fnamemodify("file", test_null_string())'])
  CheckDefSuccess(['echo fnamemodify("file", "")'])

  CheckDefExecFailure(['echo fnamemodify(true, ":p")'], 'E1013: Argument 1: type mismatch, expected string but got bool')
  CheckDefExecFailure(['echo fnamemodify(v:null, ":p")'], 'E1013: Argument 1: type mismatch, expected string but got special')
  CheckDefExecFailure(['echo fnamemodify("file", true)'],  'E1013: Argument 2: type mismatch, expected string but got bool')
enddef

def Wrong_dict_key_type(items: list<number>): list<number>
  return filter(items, (_, val) => get({[val]: 1}, 'x'))
enddef

def Test_filter()
  CheckDefAndScriptFailure2(['filter(1.1, "1")'], 'E1013: Argument 1: type mismatch, expected list<any> but got float', 'E1228: List or Dictionary or Blob required for argument 1')
  assert_equal([], filter([1, 2, 3], '0'))
  assert_equal([1, 2, 3], filter([1, 2, 3], '1'))
  assert_equal({b: 20}, filter({a: 10, b: 20}, 'v:val == 20'))
enddef

def Test_filter_wrong_dict_key_type()
  assert_fails('Wrong_dict_key_type([1, v:null, 3])', 'E1013:')
enddef

def Test_filter_return_type()
  var l = filter([1, 2, 3], (_, _) => 1)
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(6)
enddef

def Test_filter_missing_argument()
  var dict = {aa: [1], ab: [2], ac: [3], de: [4]}
  var res = dict->filter((k, _) => k =~ 'a' && k !~ 'b')
  res->assert_equal({aa: [1], ac: [3]})
enddef

def Test_foldclosed()
  CheckDefAndScriptFailure2(['foldclosed(function("min"))'], 'E1013: Argument 1: type mismatch, expected string but got func(...): any', 'E1220: String or Number required for argument 1')
  assert_equal(-1, foldclosed(1))
  assert_equal(-1, foldclosed('$'))
enddef

def Test_foldclosedend()
  CheckDefAndScriptFailure2(['foldclosedend(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1220: String or Number required for argument 1')
  assert_equal(-1, foldclosedend(1))
  assert_equal(-1, foldclosedend('w0'))
enddef

def Test_foldlevel()
  CheckDefAndScriptFailure2(['foldlevel(0z10)'], 'E1013: Argument 1: type mismatch, expected string but got blob', 'E1220: String or Number required for argument 1')
  assert_equal(0, foldlevel(1))
  assert_equal(0, foldlevel('.'))
enddef

def Test_foldtextresult()
  CheckDefAndScriptFailure2(['foldtextresult(1.1)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E1220: String or Number required for argument 1')
  assert_equal('', foldtextresult(1))
  assert_equal('', foldtextresult('.'))
enddef

def Test_fullcommand()
  assert_equal('next', fullcommand('n'))
  assert_equal('noremap', fullcommand('no'))
  assert_equal('noremap', fullcommand('nor'))
  assert_equal('normal', fullcommand('norm'))

  assert_equal('', fullcommand('k'))
  assert_equal('keepmarks', fullcommand('ke'))
  assert_equal('keepmarks', fullcommand('kee'))
  assert_equal('keepmarks', fullcommand('keep'))
  assert_equal('keepjumps', fullcommand('keepj'))

  assert_equal('dlist', fullcommand('dl'))
  assert_equal('', fullcommand('dp'))
  assert_equal('delete', fullcommand('del'))
  assert_equal('', fullcommand('dell'))
  assert_equal('', fullcommand('delp'))

  assert_equal('srewind', fullcommand('sre'))
  assert_equal('scriptnames', fullcommand('scr'))
  assert_equal('', fullcommand('scg'))
enddef

def Test_funcref()
  CheckDefAndScriptFailure2(['funcref("reverse", 2)'], 'E1013: Argument 2: type mismatch, expected list<any> but got number', 'E1211: List required for argument 2')
  CheckDefAndScriptFailure2(['funcref("reverse", [2], [1])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 3')
enddef

def Test_function()
  CheckDefAndScriptFailure2(['function("reverse", 2)'], 'E1013: Argument 2: type mismatch, expected list<any> but got number', 'E1211: List required for argument 2')
  CheckDefAndScriptFailure2(['function("reverse", [2], [1])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 3')
enddef

def Test_garbagecollect()
  garbagecollect(true)
  CheckDefAndScriptFailure2(['garbagecollect("1")'], 'E1013: Argument 1: type mismatch, expected bool but got string', 'E1212: Bool required for argument 1')
  CheckDefAndScriptFailure2(['garbagecollect(20)'], 'E1013: Argument 1: type mismatch, expected bool but got number', 'E1212: Bool required for argument 1')
enddef

def Test_get()
  CheckDefAndScriptFailure2(['get("a", 1)'], 'E1013: Argument 1: type mismatch, expected list<any> but got string', 'E896: Argument of get() must be a List, Dictionary or Blob')
  [3, 5, 2]->get(1)->assert_equal(5)
  [3, 5, 2]->get(3)->assert_equal(0)
  [3, 5, 2]->get(3, 9)->assert_equal(9)
  assert_equal(get(0z102030, 2), 0x30)
  {a: 7, b: 11, c: 13}->get('c')->assert_equal(13)
  {10: 'a', 20: 'b', 30: 'd'}->get(20)->assert_equal('b')
  function('max')->get('name')->assert_equal('max')
  var F: func = function('min', [[5, 8, 6]])
  F->get('name')->assert_equal('min')
  F->get('args')->assert_equal([[5, 8, 6]])

  var lines =<< trim END
      vim9script
      def DoThat(): number
        var Getqflist: func = function('getqflist', [{id: 42}])
        return Getqflist()->get('id', 77)
      enddef
      assert_equal(0, DoThat())
  END
  CheckScriptSuccess(lines)
enddef

def Test_getbufinfo()
  var bufinfo = getbufinfo(bufnr())
  getbufinfo('%')->assert_equal(bufinfo)

  edit Xtestfile1
  hide edit Xtestfile2
  hide enew
  getbufinfo({bufloaded: true, buflisted: true, bufmodified: false})
      ->len()->assert_equal(3)
  bwipe Xtestfile1 Xtestfile2
  CheckDefAndScriptFailure2(['getbufinfo(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1174: String required for argument 1')
enddef

def Test_getbufline()
  e SomeFile
  var buf = bufnr()
  e #
  var lines = ['aaa', 'bbb', 'ccc']
  setbufline(buf, 1, lines)
  getbufline('#', 1, '$')->assert_equal(lines)
  getbufline(-1, '$', '$')->assert_equal([])
  getbufline(-1, 1, '$')->assert_equal([])

  bwipe!
  CheckDefAndScriptFailure2(['getbufline([], 2)'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['getbufline("a", [])'], 'E1013: Argument 2: type mismatch, expected string but got list<unknown>', 'E1220: String or Number required for argument 2')
  CheckDefAndScriptFailure2(['getbufline("a", 2, 0z10)'], 'E1013: Argument 3: type mismatch, expected string but got blob', 'E1220: String or Number required for argument 3')
enddef

def Test_getbufvar()
  CheckDefAndScriptFailure2(['getbufvar(true, "v")'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['getbufvar(1, 2, 3)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
enddef

def Test_getchangelist()
  new
  setline(1, 'some text')
  var changelist = bufnr()->getchangelist()
  getchangelist('%')->assert_equal(changelist)
  bwipe!
enddef

def Test_getchar()
  while getchar(0)
  endwhile
  getchar(true)->assert_equal(0)
  getchar(1)->assert_equal(0)
  CheckDefAndScriptFailure2(['getchar(2)'], 'E1013: Argument 1: type mismatch, expected bool but got number', 'E1212: Bool required for argument 1')
  CheckDefAndScriptFailure2(['getchar("1")'], 'E1013: Argument 1: type mismatch, expected bool but got string', 'E1212: Bool required for argument 1')
enddef

def Test_getcharpos()
  CheckDefAndScriptFailure2(['getcharpos(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['getcharpos(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
enddef

def Test_getcharstr()
  CheckDefAndScriptFailure2(['getcharstr(2)'], 'E1013: Argument 1: type mismatch, expected bool but got number', 'E1212: Bool required for argument 1')
  CheckDefAndScriptFailure2(['getcharstr("1")'], 'E1013: Argument 1: type mismatch, expected bool but got string', 'E1212: Bool required for argument 1')
enddef

def Test_getcompletion()
  set wildignore=*.vim,*~
  var l = getcompletion('run', 'file', true)
  l->assert_equal([])
  set wildignore&
  CheckDefAndScriptFailure2(['getcompletion(1, "b")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['getcompletion("a", 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['getcompletion("a", "b", 2)'], 'E1013: Argument 3: type mismatch, expected bool but got number', 'E1212: Bool required for argument 3')
enddef

def Test_getcurpos()
  CheckDefAndScriptFailure2(['getcursorcharpos("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_getcursorcharpos()
  CheckDefAndScriptFailure2(['getcursorcharpos("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_getcwd()
  CheckDefAndScriptFailure2(['getcwd("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['getcwd("x", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['getcwd(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_getenv()
  if getenv('does-not_exist') == ''
    assert_report('getenv() should return null')
  endif
  if getenv('does-not_exist') == null
  else
    assert_report('getenv() should return null')
  endif
  $SOMEENVVAR = 'some'
  assert_equal('some', getenv('SOMEENVVAR'))
  unlet $SOMEENVVAR
enddef

def Test_getfontname()
  CheckDefAndScriptFailure2(['getfontname(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
enddef

def Test_getfperm()
  assert_equal('', getfperm(""))
  assert_equal('', getfperm(test_null_string()))

  CheckDefExecFailure(['echo getfperm(true)'], 'E1013:')
  CheckDefExecFailure(['echo getfperm(v:null)'], 'E1013:')
enddef

def Test_getfsize()
  assert_equal(-1, getfsize(""))
  assert_equal(-1, getfsize(test_null_string()))

  CheckDefExecFailure(['echo getfsize(true)'], 'E1013:')
  CheckDefExecFailure(['echo getfsize(v:null)'], 'E1013:')
enddef

def Test_getftime()
  assert_equal(-1, getftime(""))
  assert_equal(-1, getftime(test_null_string()))

  CheckDefExecFailure(['echo getftime(true)'], 'E1013:')
  CheckDefExecFailure(['echo getftime(v:null)'], 'E1013:')
enddef

def Test_getftype()
  assert_equal('', getftype(""))
  assert_equal('', getftype(test_null_string()))

  CheckDefExecFailure(['echo getftype(true)'], 'E1013:')
  CheckDefExecFailure(['echo getftype(v:null)'], 'E1013:')
enddef

def Test_getjumplist()
  CheckDefAndScriptFailure2(['getjumplist("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['getjumplist("x", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['getjumplist(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_getline()
  var lines =<< trim END
      new
      setline(1, ['hello', 'there', 'again'])
      assert_equal('hello', getline(1))
      assert_equal('hello', getline('.'))

      normal 2Gvjv
      assert_equal('there', getline("'<"))
      assert_equal('again', getline("'>"))
  END
  CheckDefAndScriptSuccess(lines)

  lines =<< trim END
      echo getline('1')
  END
  CheckDefExecAndScriptFailure(lines, 'E1209:')
  CheckDefAndScriptFailure2(['getline(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['getline(1, true)'], 'E1013: Argument 2: type mismatch, expected string but got bool', 'E1220: String or Number required for argument 2')
enddef

def Test_getloclist()
  CheckDefAndScriptFailure2(['getloclist("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['getloclist(1, [])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 2')
enddef

def Test_getloclist_return_type()
  var l = getloclist(1)
  l->assert_equal([])

  var d = getloclist(1, {items: 0})
  d->assert_equal({items: []})
enddef

def Test_getmarklist()
  CheckDefAndScriptFailure2(['getmarklist([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1220: String or Number required for argument 1')
  assert_equal([], getmarklist(10000))
  assert_fails('getmarklist("a%b@#")', 'E94:')
enddef

def Test_getmatches()
  CheckDefAndScriptFailure2(['getmatches("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_getpos()
  CheckDefAndScriptFailure2(['getpos(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  assert_equal([0, 1, 1, 0], getpos('.'))
  CheckDefExecFailure(['getpos("a")'], 'E1209:')
enddef

def Test_getqflist()
  CheckDefAndScriptFailure2(['getqflist([])'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 1')
  call assert_equal({}, getqflist({}))
enddef

def Test_getqflist_return_type()
  var l = getqflist()
  l->assert_equal([])

  var d = getqflist({items: 0})
  d->assert_equal({items: []})
enddef

def Test_getreg()
  var lines = ['aaa', 'bbb', 'ccc']
  setreg('a', lines)
  getreg('a', true, true)->assert_equal(lines)
  assert_fails('getreg("ab")', 'E1162:')
  CheckDefAndScriptFailure2(['getreg(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['getreg(".", 2)'], 'E1013: Argument 2: type mismatch, expected bool but got number', 'E1212: Bool required for argument 2')
  CheckDefAndScriptFailure2(['getreg(".", 1, "b")'], 'E1013: Argument 3: type mismatch, expected bool but got string', 'E1212: Bool required for argument 3')
enddef

def Test_getreg_return_type()
  var s1: string = getreg('"')
  var s2: string = getreg('"', 1)
  var s3: list<string> = getreg('"', 1, 1)
enddef

def Test_getreginfo()
  var text = 'abc'
  setreg('a', text)
  getreginfo('a')->assert_equal({regcontents: [text], regtype: 'v', isunnamed: false})
  assert_fails('getreginfo("ab")', 'E1162:')
enddef

def Test_getregtype()
  var lines = ['aaa', 'bbb', 'ccc']
  setreg('a', lines)
  getregtype('a')->assert_equal('V')
  assert_fails('getregtype("ab")', 'E1162:')
enddef

def Test_gettabinfo()
  CheckDefAndScriptFailure2(['gettabinfo("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_gettabvar()
  CheckDefAndScriptFailure2(['gettabvar("a", "b")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['gettabvar(1, 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
enddef

def Test_gettabwinvar()
  CheckDefAndScriptFailure2(['gettabwinvar("a", 2, "c")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['gettabwinvar(1, "b", "c", [])'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['gettabwinvar(1, 1, 3, {})'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E1174: String required for argument 3')
enddef

def Test_gettagstack()
  CheckDefAndScriptFailure2(['gettagstack("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_gettext()
  CheckDefAndScriptFailure2(['gettext(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  assert_equal('abc', gettext("abc"))
enddef

def Test_getwininfo()
  CheckDefAndScriptFailure2(['getwininfo("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_getwinpos()
  CheckDefAndScriptFailure2(['getwinpos("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_getwinvar()
  CheckDefAndScriptFailure2(['getwinvar("a", "b")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['getwinvar(1, 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
enddef

def Test_glob()
  glob('runtest.vim', true, true, true)->assert_equal(['runtest.vim'])
  CheckDefAndScriptFailure2(['glob(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['glob("a", 2)'], 'E1013: Argument 2: type mismatch, expected bool but got number', 'E1212: Bool required for argument 2')
  CheckDefAndScriptFailure2(['glob("a", 1, "b")'], 'E1013: Argument 3: type mismatch, expected bool but got string', 'E1212: Bool required for argument 3')
  CheckDefAndScriptFailure2(['glob("a", 1, true, 2)'], 'E1013: Argument 4: type mismatch, expected bool but got number', 'E1212: Bool required for argument 4')
enddef

def Test_glob2regpat()
  CheckDefAndScriptFailure2(['glob2regpat(null)'], 'E1013: Argument 1: type mismatch, expected string but got special', 'E1174: String required for argument 1')
  assert_equal('^$', glob2regpat(''))
enddef

def Test_globpath()
  globpath('.', 'runtest.vim', true, true, true)->assert_equal(['./runtest.vim'])
  CheckDefAndScriptFailure2(['globpath(1, "b")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['globpath("a", 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['globpath("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected bool but got string', 'E1212: Bool required for argument 3')
  CheckDefAndScriptFailure2(['globpath("a", "b", true, "d")'], 'E1013: Argument 4: type mismatch, expected bool but got string', 'E1212: Bool required for argument 4')
  CheckDefAndScriptFailure2(['globpath("a", "b", true, false, "e")'], 'E1013: Argument 5: type mismatch, expected bool but got string', 'E1212: Bool required for argument 5')
enddef

def Test_has()
  has('eval', true)->assert_equal(1)
  CheckDefAndScriptFailure2(['has(["a"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['has("a", "b")'], 'E1013: Argument 2: type mismatch, expected bool but got string', 'E1212: Bool required for argument 2')
enddef

def Test_has_key()
  var d = {123: 'xx'}
  assert_true(has_key(d, '123'))
  assert_true(has_key(d, 123))
  assert_false(has_key(d, 'x'))
  assert_false(has_key(d, 99))

  CheckDefAndScriptFailure2(['has_key([1, 2], "k")'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 1')
  CheckDefAndScriptFailure2(['has_key({"a": 10}, ["a"])'], 'E1013: Argument 2: type mismatch, expected string but got list<string>', 'E1220: String or Number required for argument 2')
enddef

def Test_haslocaldir()
  CheckDefAndScriptFailure2(['haslocaldir("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['haslocaldir("x", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['haslocaldir(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_hasmapto()
  hasmapto('foobar', 'i', true)->assert_equal(0)
  iabbrev foo foobar
  hasmapto('foobar', 'i', true)->assert_equal(1)
  iunabbrev foo
  CheckDefAndScriptFailure2(['hasmapto(1, "b")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['hasmapto("a", 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['hasmapto("a", "b", 2)'], 'E1013: Argument 3: type mismatch, expected bool but got number', 'E1212: Bool required for argument 3')
enddef

def Test_histadd()
  CheckDefAndScriptFailure2(['histadd(1, "x")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['histadd(":", 10)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  histadd("search", 'skyblue')
  assert_equal('skyblue', histget('/', -1))
enddef

def Test_histdel()
  CheckDefAndScriptFailure2(['histdel(1, "x")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['histdel(":", true)'], 'E1013: Argument 2: type mismatch, expected string but got bool', 'E1220: String or Number required for argument 2')
enddef

def Test_histget()
  CheckDefAndScriptFailure2(['histget(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['histget("a", "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_histnr()
  CheckDefAndScriptFailure2(['histnr(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  assert_equal(-1, histnr('abc'))
enddef

def Test_hlID()
  CheckDefAndScriptFailure2(['hlID(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  assert_equal(0, hlID('NonExistingHighlight'))
enddef

def Test_hlexists()
  CheckDefAndScriptFailure2(['hlexists([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1174: String required for argument 1')
  assert_equal(0, hlexists('NonExistingHighlight'))
enddef

def Test_iconv()
  CheckDefAndScriptFailure2(['iconv(1, "from", "to")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['iconv("abc", 10, "to")'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['iconv("abc", "from", 20)'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E1174: String required for argument 3')
  assert_equal('abc', iconv('abc', 'fromenc', 'toenc'))
enddef

def Test_indent()
  CheckDefAndScriptFailure2(['indent([1])'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['indent(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1220: String or Number required for argument 1')
  assert_equal(0, indent(1))
enddef

def Test_index()
  index(['a', 'b', 'a', 'B'], 'b', 2, true)->assert_equal(3)
  CheckDefAndScriptFailure2(['index("a", "a")'], 'E1013: Argument 1: type mismatch, expected list<any> but got string', 'E1226: String or List required for argument 1')
  CheckDefFailure(['index(["1"], 1)'], 'E1013: Argument 2: type mismatch, expected string but got number')
  CheckDefAndScriptFailure2(['index(0z10, "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['index([1], 1, "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  CheckDefAndScriptFailure2(['index(0z1020, 10, 1, 2)'], 'E1013: Argument 4: type mismatch, expected bool but got number', 'E1212: Bool required for argument 4')
enddef

def Test_input()
  CheckDefAndScriptFailure2(['input(5)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['input(["a"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['input("p", 10)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['input("p", "q", 20)'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E1174: String required for argument 3')
enddef

def Test_inputdialog()
  CheckDefAndScriptFailure2(['inputdialog(5)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['inputdialog(["a"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['inputdialog("p", 10)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['inputdialog("p", "q", 20)'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E1174: String required for argument 3')
enddef

def Test_inputlist()
  CheckDefAndScriptFailure2(['inputlist(10)'], 'E1013: Argument 1: type mismatch, expected list<string> but got number', 'E1211: List required for argument 1')
  CheckDefAndScriptFailure2(['inputlist("abc")'], 'E1013: Argument 1: type mismatch, expected list<string> but got string', 'E1211: List required for argument 1')
  CheckDefFailure(['inputlist([1, 2, 3])'], 'E1013: Argument 1: type mismatch, expected list<string> but got list<number>')
  feedkeys("2\<CR>", 't')
  var r: number = inputlist(['a', 'b', 'c'])
  assert_equal(2, r)
enddef

def Test_inputsecret()
  CheckDefAndScriptFailure2(['inputsecret(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['inputsecret("Pass:", 20)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  feedkeys("\<CR>", 't')
  var ans: string = inputsecret('Pass:', '123')
  assert_equal('123', ans)
enddef

let s:number_one = 1
let s:number_two = 2
let s:string_keep = 'keep'

def Test_insert()
  var l = insert([2, 1], 3)
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(6)

  var m: any = []
  insert(m, 4)
  call assert_equal([4], m)
  extend(m, [6], 0)
  call assert_equal([6, 4], m)

  var lines =<< trim END
      insert(test_null_list(), 123)
  END
  CheckDefExecAndScriptFailure(lines, 'E1130:', 1)

  lines =<< trim END
      insert(test_null_blob(), 123)
  END
  CheckDefExecAndScriptFailure(lines, 'E1131:', 1)

  assert_equal([1, 2, 3], insert([2, 3], 1))
  assert_equal([1, 2, 3], insert([2, 3], s:number_one))
  assert_equal([1, 2, 3], insert([1, 2], 3, 2))
  assert_equal([1, 2, 3], insert([1, 2], 3, s:number_two))
  assert_equal(['a', 'b', 'c'], insert(['b', 'c'], 'a'))
  assert_equal(0z1234, insert(0z34, 0x12))

  CheckDefAndScriptFailure2(['insert("a", 1)'], 'E1013: Argument 1: type mismatch, expected list<any> but got string', 'E1226: String or List required for argument 1')
  CheckDefFailure(['insert([2, 3], "a")'], 'E1013: Argument 2: type mismatch, expected number but got string')
  CheckDefAndScriptFailure2(['insert([2, 3], 1, "x")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
enddef

def Test_invert()
  CheckDefAndScriptFailure2(['invert("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_isdirectory()
  CheckDefAndScriptFailure2(['isdirectory(1.1)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E1174: String required for argument 1')
  assert_false(isdirectory('NonExistingDir'))
enddef

def Test_islocked()
  CheckDefAndScriptFailure2(['islocked(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['var n1: number = 10', 'islocked(n1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  g:v1 = 10
  assert_false(islocked('g:v1'))
  lockvar g:v1
  assert_true(islocked('g:v1'))
  unlet g:v1
enddef

def Test_items()
  CheckDefFailure(['[]->items()'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<unknown>')
  assert_equal([['a', 10], ['b', 20]], {'a': 10, 'b': 20}->items())
  assert_equal([], {}->items())
enddef

def Test_job_getchannel()
  if !has('job')
    CheckFeature job
  else
    CheckDefAndScriptFailure2(['job_getchannel("a")'], 'E1013: Argument 1: type mismatch, expected job but got string', 'E1218: Job required for argument 1')
    assert_fails('job_getchannel(test_null_job())', 'E916: not a valid job')
  endif
enddef

def Test_job_info()
  if !has('job')
    CheckFeature job
  else
    CheckDefAndScriptFailure2(['job_info("a")'], 'E1013: Argument 1: type mismatch, expected job but got string', 'E1218: Job required for argument 1')
    assert_fails('job_info(test_null_job())', 'E916: not a valid job')
  endif
enddef

def Test_job_info_return_type()
  if !has('job')
    CheckFeature job
  else
    job_start(&shell)
    var jobs = job_info()
    assert_equal('list<job>', typename(jobs))
    assert_equal('dict<any>', typename(job_info(jobs[0])))
    job_stop(jobs[0])
  endif
enddef

def Test_job_setoptions()
  if !has('job')
    CheckFeature job
  else
    CheckDefAndScriptFailure2(['job_setoptions(test_null_channel(), {})'], 'E1013: Argument 1: type mismatch, expected job but got channel', 'E1218: Job required for argument 1')
    CheckDefAndScriptFailure2(['job_setoptions(test_null_job(), [])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 2')
    assert_equal('fail', job_status(test_null_job()))
  endif
enddef

def Test_job_status()
  if !has('job')
    CheckFeature job
  else
    CheckDefAndScriptFailure2(['job_status("a")'], 'E1013: Argument 1: type mismatch, expected job but got string', 'E1218: Job required for argument 1')
    assert_equal('fail', job_status(test_null_job()))
  endif
enddef

def Test_job_stop()
  if !has('job')
    CheckFeature job
  else
    CheckDefAndScriptFailure2(['job_stop("a")'], 'E1013: Argument 1: type mismatch, expected job but got string', 'E1218: Job required for argument 1')
    CheckDefAndScriptFailure2(['job_stop(test_null_job(), true)'], 'E1013: Argument 2: type mismatch, expected string but got bool', 'E1220: String or Number required for argument 2')
  endif
enddef

def Test_join()
  CheckDefAndScriptFailure2(['join("abc")'], 'E1013: Argument 1: type mismatch, expected list<any> but got string', 'E1211: List required for argument 1')
  CheckDefAndScriptFailure2(['join([], 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
enddef

def Test_js_decode()
  CheckDefAndScriptFailure2(['js_decode(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  assert_equal([1, 2], js_decode('[1,2]'))
enddef

def Test_json_decode()
  CheckDefAndScriptFailure2(['json_decode(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1174: String required for argument 1')
  assert_equal(1.0, json_decode('1.0'))
enddef

def Test_keys()
  CheckDefAndScriptFailure2(['keys([])'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 1')
  assert_equal(['a'], {a: 'v'}->keys())
  assert_equal([], {}->keys())
enddef

def Test_keys_return_type()
  const var: list<string> = {a: 1, b: 2}->keys()
  var->assert_equal(['a', 'b'])
enddef

def Test_len()
  CheckDefAndScriptFailure2(['len(true)'], 'E1013: Argument 1: type mismatch, expected list<any> but got bool', 'E701: Invalid type for len()')
  assert_equal(2, "ab"->len())
  assert_equal(3, 456->len())
  assert_equal(0, []->len())
  assert_equal(1, {a: 10}->len())
  assert_equal(4, 0z20304050->len())
enddef

def Test_libcall()
  CheckFeature libcall
  CheckDefAndScriptFailure2(['libcall(1, "b", 3)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['libcall("a", 2, 3)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['libcall("a", "b", 1.1)'], 'E1013: Argument 3: type mismatch, expected string but got float', 'E1220: String or Number required for argument 3')
enddef

def Test_libcallnr()
  CheckFeature libcall
  CheckDefAndScriptFailure2(['libcallnr(1, "b", 3)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['libcallnr("a", 2, 3)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['libcallnr("a", "b", 1.1)'], 'E1013: Argument 3: type mismatch, expected string but got float', 'E1220: String or Number required for argument 3')
enddef

def Test_line()
  assert_fails('line(true)', 'E1174:')
  CheckDefAndScriptFailure2(['line(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['line(".", "a")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_line2byte()
  CheckDefAndScriptFailure2(['line2byte(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1220: String or Number required for argument 1')
  assert_equal(-1, line2byte(1))
  assert_equal(-1, line2byte(10000))
enddef

def Test_lispindent()
  CheckDefAndScriptFailure2(['lispindent({})'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>', 'E1220: String or Number required for argument 1')
  assert_equal(0, lispindent(1))
enddef

def Test_list2str_str2list_utf8()
  var s = "\u3042\u3044"
  var l = [0x3042, 0x3044]
  str2list(s, true)->assert_equal(l)
  list2str(l, true)->assert_equal(s)
enddef

def Test_list2str()
  CheckDefAndScriptFailure2(['list2str(".", true)'], 'E1013: Argument 1: type mismatch, expected list<number> but got string', 'E1211: List required for argument 1')
  CheckDefAndScriptFailure2(['list2str([1], 0z10)'], 'E1013: Argument 2: type mismatch, expected bool but got blob', 'E1212: Bool required for argument 2')
enddef

def SID(): number
  return expand('<SID>')
          ->matchstr('<SNR>\zs\d\+\ze_$')
          ->str2nr()
enddef

def Test_listener_add()
  CheckDefAndScriptFailure2(['listener_add("1", true)'], 'E1013: Argument 2: type mismatch, expected string but got bool', 'E1220: String or Number required for argument 2')
enddef

def Test_listener_flush()
  CheckDefAndScriptFailure2(['listener_flush([1])'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1220: String or Number required for argument 1')
enddef

def Test_listener_remove()
  CheckDefAndScriptFailure2(['listener_remove("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_lua()
  if !has('lua')
    CheckFeature lua
  endif
  CheckDefAndScriptFailure2(['luaeval(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
enddef

def Test_map()
  CheckDefAndScriptFailure2(['map("x", "1")'], 'E1013: Argument 1: type mismatch, expected list<any> but got string', 'E1228: List or Dictionary or Blob required for argument 1')
  CheckDefAndScriptFailure2(['map(1, "1")'], 'E1013: Argument 1: type mismatch, expected list<any> but got number', 'E1228: List or Dictionary or Blob required for argument 1')
enddef

def Test_map_failure()
  CheckFeature job

  var lines =<< trim END
      vim9script
      writefile([], 'Xtmpfile')
      silent e Xtmpfile
      var d = {[bufnr('%')]: {a: 0}}
      au BufReadPost * Func()
      def Func()
          if d->has_key('')
          endif
          eval d[expand('<abuf>')]->mapnew((_, v: dict<job>) => 0)
      enddef
      e
  END
  CheckScriptFailure(lines, 'E1013:')
  au! BufReadPost
  delete('Xtmpfile')
enddef

def Test_map_function_arg()
  var lines =<< trim END
      def MapOne(i: number, v: string): string
        return i .. ':' .. v
      enddef
      var l = ['a', 'b', 'c']
      map(l, MapOne)
      assert_equal(['0:a', '1:b', '2:c'], l)
  END
  CheckDefAndScriptSuccess(lines)

  lines =<< trim END
      range(3)->map((a, b, c) => a + b + c)
  END
  CheckDefExecAndScriptFailure(lines, 'E1190: One argument too few')
  lines =<< trim END
      range(3)->map((a, b, c, d) => a + b + c + d)
  END
  CheckDefExecAndScriptFailure(lines, 'E1190: 2 arguments too few')
enddef

def Test_map_item_type()
  var lines =<< trim END
      var l = ['a', 'b', 'c']
      map(l, (k, v) => k .. '/' .. v )
      assert_equal(['0/a', '1/b', '2/c'], l)
  END
  CheckDefAndScriptSuccess(lines)

  lines =<< trim END
    var l: list<number> = [0]
    echo map(l, (_, v) => [])
  END
  CheckDefExecAndScriptFailure(lines, 'E1012: Type mismatch; expected number but got list<unknown> in map()', 2)

  lines =<< trim END
    var l: list<number> = range(2)
    echo map(l, (_, v) => [])
  END
  CheckDefExecAndScriptFailure(lines, 'E1012: Type mismatch; expected number but got list<unknown> in map()', 2)

  lines =<< trim END
    var d: dict<number> = {key: 0}
    echo map(d, (_, v) => [])
  END
  CheckDefExecAndScriptFailure(lines, 'E1012: Type mismatch; expected number but got list<unknown> in map()', 2)
enddef

def Test_maparg()
  var lnum = str2nr(expand('<sflnum>'))
  map foo bar
  maparg('foo', '', false, true)->assert_equal({
        lnum: lnum + 1,
        script: 0,
        mode: ' ',
        silent: 0,
        noremap: 0,
        lhs: 'foo',
        lhsraw: 'foo',
        nowait: 0,
        expr: 0,
        sid: SID(),
        rhs: 'bar',
        buffer: 0})
  unmap foo
  CheckDefAndScriptFailure2(['maparg(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['maparg("a", 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['maparg("a", "b", 2)'], 'E1013: Argument 3: type mismatch, expected bool but got number', 'E1212: Bool required for argument 3')
  CheckDefAndScriptFailure2(['maparg("a", "b", true, 2)'], 'E1013: Argument 4: type mismatch, expected bool but got number', 'E1212: Bool required for argument 4')
enddef

def Test_maparg_mapset()
  nnoremap <F3> :echo "hit F3"<CR>
  var mapsave = maparg('<F3>', 'n', false, true)
  mapset('n', false, mapsave)

  nunmap <F3>
enddef

def Test_mapcheck()
  iabbrev foo foobar
  mapcheck('foo', 'i', true)->assert_equal('foobar')
  iunabbrev foo
  CheckDefAndScriptFailure2(['mapcheck(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['mapcheck("a", 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['mapcheck("a", "b", 2)'], 'E1013: Argument 3: type mismatch, expected bool but got number', 'E1212: Bool required for argument 3')
enddef

def Test_mapnew()
  CheckDefAndScriptFailure2(['mapnew("x", "1")'], 'E1013: Argument 1: type mismatch, expected list<any> but got string', 'E1228: List or Dictionary or Blob required for argument 1')
  CheckDefAndScriptFailure2(['mapnew(1, "1")'], 'E1013: Argument 1: type mismatch, expected list<any> but got number', 'E1228: List or Dictionary or Blob required for argument 1')
enddef

def Test_mapset()
  CheckDefAndScriptFailure2(['mapset(1, true, {})'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['mapset("a", 2, {})'], 'E1013: Argument 2: type mismatch, expected bool but got number', 'E1212: Bool required for argument 2')
  CheckDefAndScriptFailure2(['mapset("a", false, [])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 3')
enddef

def Test_match()
  CheckDefAndScriptFailure2(['match(0z12, "p")'], 'E1013: Argument 1: type mismatch, expected string but got blob', 'E1222: String or List required for argument 1')
  CheckDefAndScriptFailure2(['match(["s"], [2])'], 'E1013: Argument 2: type mismatch, expected string but got list<number>', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['match("s", "p", "q")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  CheckDefAndScriptFailure2(['match("s", "p", 1, "r")'], 'E1013: Argument 4: type mismatch, expected number but got string', 'E1210: Number required for argument 4')
  assert_equal(2, match('ab12cd', '12'))
  assert_equal(-1, match('ab12cd', '34'))
  assert_equal(6, match('ab12cd12ef', '12', 4))
  assert_equal(2, match('abcd', '..', 0, 3))
  assert_equal(1, match(['a', 'b', 'c'], 'b'))
  assert_equal(-1, match(['a', 'b', 'c'], 'd'))
  assert_equal(3, match(['a', 'b', 'c', 'b', 'd', 'b'], 'b', 2))
  assert_equal(5, match(['a', 'b', 'c', 'b', 'd', 'b'], 'b', 2, 2))
enddef

def Test_matchadd()
  CheckDefAndScriptFailure2(['matchadd(1, "b")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['matchadd("a", 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['matchadd("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  CheckDefAndScriptFailure2(['matchadd("a", "b", 1, "d")'], 'E1013: Argument 4: type mismatch, expected number but got string', 'E1210: Number required for argument 4')
  CheckDefAndScriptFailure2(['matchadd("a", "b", 1, 1, [])'], 'E1013: Argument 5: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 5')
enddef

def Test_matchaddpos()
  CheckDefAndScriptFailure2(['matchaddpos(1, [1])'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['matchaddpos("a", "b")'], 'E1013: Argument 2: type mismatch, expected list<any> but got string', 'E1211: List required for argument 2')
  CheckDefAndScriptFailure2(['matchaddpos("a", [1], "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  CheckDefAndScriptFailure2(['matchaddpos("a", [1], 1, "d")'], 'E1013: Argument 4: type mismatch, expected number but got string', 'E1210: Number required for argument 4')
  CheckDefAndScriptFailure2(['matchaddpos("a", [1], 1, 1, [])'], 'E1013: Argument 5: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 5')
enddef

def Test_matcharg()
  CheckDefAndScriptFailure2(['matcharg("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_matchdelete()
  CheckDefAndScriptFailure2(['matchdelete("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['matchdelete("x", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['matchdelete(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_matchend()
  CheckDefAndScriptFailure2(['matchend(0z12, "p")'], 'E1013: Argument 1: type mismatch, expected string but got blob', 'E1222: String or List required for argument 1')
  CheckDefAndScriptFailure2(['matchend(["s"], [2])'], 'E1013: Argument 2: type mismatch, expected string but got list<number>', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['matchend("s", "p", "q")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  CheckDefAndScriptFailure2(['matchend("s", "p", 1, "r")'], 'E1013: Argument 4: type mismatch, expected number but got string', 'E1210: Number required for argument 4')
  assert_equal(4, matchend('ab12cd', '12'))
  assert_equal(-1, matchend('ab12cd', '34'))
  assert_equal(8, matchend('ab12cd12ef', '12', 4))
  assert_equal(4, matchend('abcd', '..', 0, 3))
  assert_equal(1, matchend(['a', 'b', 'c'], 'b'))
  assert_equal(-1, matchend(['a', 'b', 'c'], 'd'))
  assert_equal(3, matchend(['a', 'b', 'c', 'b', 'd', 'b'], 'b', 2))
  assert_equal(5, matchend(['a', 'b', 'c', 'b', 'd', 'b'], 'b', 2, 2))
enddef

def Test_matchfuzzy()
  CheckDefAndScriptFailure2(['matchfuzzy({}, "p")'], 'E1013: Argument 1: type mismatch, expected list<any> but got dict<unknown>', 'E1211: List required for argument 1')
  CheckDefAndScriptFailure2(['matchfuzzy([], 1)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['matchfuzzy([], "a", [])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 3')
enddef

def Test_matchfuzzypos()
  CheckDefAndScriptFailure2(['matchfuzzypos({}, "p")'], 'E1013: Argument 1: type mismatch, expected list<any> but got dict<unknown>', 'E1211: List required for argument 1')
  CheckDefAndScriptFailure2(['matchfuzzypos([], 1)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['matchfuzzypos([], "a", [])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 3')
enddef

def Test_matchlist()
  CheckDefAndScriptFailure2(['matchlist(0z12, "p")'], 'E1013: Argument 1: type mismatch, expected string but got blob', 'E1222: String or List required for argument 1')
  CheckDefAndScriptFailure2(['matchlist(["s"], [2])'], 'E1013: Argument 2: type mismatch, expected string but got list<number>', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['matchlist("s", "p", "q")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  CheckDefAndScriptFailure2(['matchlist("s", "p", 1, "r")'], 'E1013: Argument 4: type mismatch, expected number but got string', 'E1210: Number required for argument 4')
  var l: list<string> = ['12',  '', '', '', '', '', '', '', '', '']
  assert_equal(l, matchlist('ab12cd', '12'))
  assert_equal([], matchlist('ab12cd', '34'))
  assert_equal(l, matchlist('ab12cd12ef', '12', 4))
  l[0] = 'cd'
  assert_equal(l, matchlist('abcd', '..', 0, 3))
  l[0] = 'b'
  assert_equal(l, matchlist(['a', 'b', 'c'], 'b'))
  assert_equal([], matchlist(['a', 'b', 'c'], 'd'))
  assert_equal(l, matchlist(['a', 'b', 'c', 'b', 'd', 'b'], 'b', 2))
  assert_equal(l, matchlist(['a', 'b', 'c', 'b', 'd', 'b'], 'b', 2, 2))
enddef

def Test_matchstr()
  CheckDefAndScriptFailure2(['matchstr(0z12, "p")'], 'E1013: Argument 1: type mismatch, expected string but got blob', 'E1222: String or List required for argument 1')
  CheckDefAndScriptFailure2(['matchstr(["s"], [2])'], 'E1013: Argument 2: type mismatch, expected string but got list<number>', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['matchstr("s", "p", "q")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  CheckDefAndScriptFailure2(['matchstr("s", "p", 1, "r")'], 'E1013: Argument 4: type mismatch, expected number but got string', 'E1210: Number required for argument 4')
  assert_equal('12', matchstr('ab12cd', '12'))
  assert_equal('', matchstr('ab12cd', '34'))
  assert_equal('12', matchstr('ab12cd12ef', '12', 4))
  assert_equal('cd', matchstr('abcd', '..', 0, 3))
  assert_equal('b', matchstr(['a', 'b', 'c'], 'b'))
  assert_equal('', matchstr(['a', 'b', 'c'], 'd'))
  assert_equal('b', matchstr(['a', 'b', 'c', 'b', 'd', 'b'], 'b', 2))
  assert_equal('b', matchstr(['a', 'b', 'c', 'b', 'd', 'b'], 'b', 2, 2))
enddef

def Test_matchstrpos()
  CheckDefAndScriptFailure2(['matchstrpos(0z12, "p")'], 'E1013: Argument 1: type mismatch, expected string but got blob', 'E1222: String or List required for argument 1')
  CheckDefAndScriptFailure2(['matchstrpos(["s"], [2])'], 'E1013: Argument 2: type mismatch, expected string but got list<number>', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['matchstrpos("s", "p", "q")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  CheckDefAndScriptFailure2(['matchstrpos("s", "p", 1, "r")'], 'E1013: Argument 4: type mismatch, expected number but got string', 'E1210: Number required for argument 4')
  assert_equal(['12', 2, 4], matchstrpos('ab12cd', '12'))
  assert_equal(['', -1, -1], matchstrpos('ab12cd', '34'))
  assert_equal(['12', 6, 8], matchstrpos('ab12cd12ef', '12', 4))
  assert_equal(['cd', 2, 4], matchstrpos('abcd', '..', 0, 3))
  assert_equal(['b', 1, 0, 1], matchstrpos(['a', 'b', 'c'], 'b'))
  assert_equal(['', -1, -1, -1], matchstrpos(['a', 'b', 'c'], 'd'))
  assert_equal(['b', 3, 0, 1],
                    matchstrpos(['a', 'b', 'c', 'b', 'd', 'b'], 'b', 2))
  assert_equal(['b', 5, 0, 1],
                    matchstrpos(['a', 'b', 'c', 'b', 'd', 'b'], 'b', 2, 2))
enddef

def Test_max()
  g:flag = true
  var l1: list<number> = g:flag
          ? [1, max([2, 3])]
          : [4, 5]
  assert_equal([1, 3], l1)

  g:flag = false
  var l2: list<number> = g:flag
          ? [1, max([2, 3])]
          : [4, 5]
  assert_equal([4, 5], l2)
  CheckDefAndScriptFailure2(['max(5)'], 'E1013: Argument 1: type mismatch, expected list<any> but got number', 'E1227: List or Dictionary required for argument 1')
enddef

def Test_menu_info()
  CheckDefAndScriptFailure2(['menu_info(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['menu_info(10, "n")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['menu_info("File", 10)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  assert_equal({}, menu_info('aMenu'))
enddef

def Test_min()
  g:flag = true
  var l1: list<number> = g:flag
          ? [1, min([2, 3])]
          : [4, 5]
  assert_equal([1, 2], l1)

  g:flag = false
  var l2: list<number> = g:flag
          ? [1, min([2, 3])]
          : [4, 5]
  assert_equal([4, 5], l2)
  CheckDefAndScriptFailure2(['min(5)'], 'E1013: Argument 1: type mismatch, expected list<any> but got number', 'E1227: List or Dictionary required for argument 1')
enddef

def Test_mkdir()
  CheckDefAndScriptFailure2(['mkdir(["a"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['mkdir("a", {})'], 'E1013: Argument 2: type mismatch, expected string but got dict<unknown>', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['mkdir("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  delete('a', 'rf')
enddef

def Test_mode()
  CheckDefAndScriptFailure2(['mode("1")'], 'E1013: Argument 1: type mismatch, expected bool but got string', 'E1212: Bool required for argument 1')
  CheckDefAndScriptFailure2(['mode(2)'], 'E1013: Argument 1: type mismatch, expected bool but got number', 'E1212: Bool required for argument 1')
enddef

def Test_mzeval()
  if !has('mzscheme')
    CheckFeature mzscheme
  endif
  CheckDefAndScriptFailure2(['mzeval(["a"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E1174: String required for argument 1')
enddef

def Test_nextnonblank()
  CheckDefAndScriptFailure2(['nextnonblank(null)'], 'E1013: Argument 1: type mismatch, expected string but got special', 'E1220: String or Number required for argument 1')
  assert_equal(0, nextnonblank(1))
enddef

def Test_nr2char()
  nr2char(97, true)->assert_equal('a')
  CheckDefAndScriptFailure2(['nr2char("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['nr2char(1, "a")'], 'E1013: Argument 2: type mismatch, expected bool but got string', 'E1212: Bool required for argument 2')
enddef

def Test_or()
  CheckDefAndScriptFailure2(['or("x", 0x2)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['or(0x1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_pathshorten()
  CheckDefAndScriptFailure2(['pathshorten(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['pathshorten("a", "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_perleval()
  if !has('perl')
    CheckFeature perl
  endif
  CheckDefAndScriptFailure2(['perleval(["a"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E1174: String required for argument 1')
enddef

def Test_popup_atcursor()
  CheckDefAndScriptFailure2(['popup_atcursor({"a": 10}, {})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1224: String or List required for argument 1')
  CheckDefAndScriptFailure2(['popup_atcursor("a", [1, 2])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 2')

  # Pass variable of type 'any' to popup_atcursor()
  var what: any = 'Hello'
  var popupID = what->popup_atcursor({moved: 'any'})
  assert_equal(0, popupID->popup_getoptions().tabpage)
  popupID->popup_close()
enddef

def Test_popup_beval()
  CheckDefAndScriptFailure2(['popup_beval({"a": 10}, {})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1224: String or List required for argument 1')
  CheckDefAndScriptFailure2(['popup_beval("a", [1, 2])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 2')
enddef

def Test_popup_clear()
  CheckDefAndScriptFailure2(['popup_clear(["a"])'], 'E1013: Argument 1: type mismatch, expected bool but got list<string>', 'E1212: Bool required for argument 1')
  CheckDefAndScriptFailure2(['popup_clear(2)'], 'E1013: Argument 1: type mismatch, expected bool but got number', 'E1212: Bool required for argument 1')
enddef

def Test_popup_close()
  CheckDefAndScriptFailure2(['popup_close("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_popup_create()
  # Pass variable of type 'any' to popup_create()
  var what: any = 'Hello'
  var popupID = what->popup_create({})
  assert_equal(0, popupID->popup_getoptions().tabpage)
  popupID->popup_close()
enddef

def Test_popup_dialog()
  CheckDefAndScriptFailure2(['popup_dialog({"a": 10}, {})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1224: String or List required for argument 1')
  CheckDefAndScriptFailure2(['popup_dialog("a", [1, 2])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 2')
enddef

def Test_popup_filter_menu()
  CheckDefAndScriptFailure2(['popup_filter_menu("x", "")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['popup_filter_menu(1, 1)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
enddef

def Test_popup_filter_yesno()
  CheckDefAndScriptFailure2(['popup_filter_yesno("x", "")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['popup_filter_yesno(1, 1)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
enddef

def Test_popup_getoptions()
  CheckDefAndScriptFailure2(['popup_getoptions("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['popup_getoptions(true)'], 'E1013: Argument 1: type mismatch, expected number but got bool', 'E1210: Number required for argument 1')
enddef

def Test_popup_getpos()
  CheckDefAndScriptFailure2(['popup_getpos("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['popup_getpos(true)'], 'E1013: Argument 1: type mismatch, expected number but got bool', 'E1210: Number required for argument 1')
enddef

def Test_popup_hide()
  CheckDefAndScriptFailure2(['popup_hide("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['popup_hide(true)'], 'E1013: Argument 1: type mismatch, expected number but got bool', 'E1210: Number required for argument 1')
enddef

def Test_popup_locate()
  CheckDefAndScriptFailure2(['popup_locate("a", 20)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['popup_locate(10, "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_popup_menu()
  CheckDefAndScriptFailure2(['popup_menu({"a": 10}, {})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1224: String or List required for argument 1')
  CheckDefAndScriptFailure2(['popup_menu("a", [1, 2])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 2')
enddef

def Test_popup_move()
  CheckDefAndScriptFailure2(['popup_move("x", {})'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['popup_move(1, [])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 2')
enddef

def Test_popup_notification()
  CheckDefAndScriptFailure2(['popup_notification({"a": 10}, {})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1224: String or List required for argument 1')
  CheckDefAndScriptFailure2(['popup_notification("a", [1, 2])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 2')
enddef

def Test_popup_setoptions()
  CheckDefAndScriptFailure2(['popup_setoptions("x", {})'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['popup_setoptions(1, [])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 2')
enddef

def Test_popup_settext()
  CheckDefAndScriptFailure2(['popup_settext("x", [])'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['popup_settext(1, 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1222: String or List required for argument 2')
enddef

def Test_popup_show()
  CheckDefAndScriptFailure2(['popup_show("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['popup_show(true)'], 'E1013: Argument 1: type mismatch, expected number but got bool', 'E1210: Number required for argument 1')
enddef

def Test_prevnonblank()
  CheckDefAndScriptFailure2(['prevnonblank(null)'], 'E1013: Argument 1: type mismatch, expected string but got special', 'E1220: String or Number required for argument 1')
  assert_equal(0, prevnonblank(1))
enddef

def Test_printf()
  CheckDefAndScriptFailure2(['printf([1])'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1220: String or Number required for argument 1')
  printf(0x10)->assert_equal('16')
  assert_equal(" abc", "abc"->printf("%4s"))
enddef

def Test_prompt_getprompt()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['prompt_getprompt([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1220: String or Number required for argument 1')
    assert_equal('', prompt_getprompt('NonExistingBuf'))
  endif
enddef

def Test_prompt_setcallback()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['prompt_setcallback(true, "1")'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1220: String or Number required for argument 1')
  endif
enddef

def Test_prompt_setinterrupt()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['prompt_setinterrupt(true, "1")'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1220: String or Number required for argument 1')
  endif
enddef

def Test_prompt_setprompt()
  if !has('channel')
    CheckFeature channel
  else
    CheckDefAndScriptFailure2(['prompt_setprompt([], "p")'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1220: String or Number required for argument 1')
    CheckDefAndScriptFailure2(['prompt_setprompt(1, [])'], 'E1013: Argument 2: type mismatch, expected string but got list<unknown>', 'E1174: String required for argument 2')
  endif
enddef

def Test_prop_add()
  CheckDefAndScriptFailure2(['prop_add("a", 2, {})'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['prop_add(1, "b", {})'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['prop_add(1, 2, [])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 3')
enddef

def Test_prop_clear()
  CheckDefAndScriptFailure2(['prop_clear("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['prop_clear(1, "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['prop_clear(1, 2, [])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 3')
enddef

def Test_prop_find()
  CheckDefAndScriptFailure2(['prop_find([1, 2])'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 1')
  CheckDefAndScriptFailure2(['prop_find([1, 2], "k")'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 1')
  CheckDefAndScriptFailure2(['prop_find({"a": 10}, ["a"])'], 'E1013: Argument 2: type mismatch, expected string but got list<string>', 'E1174: String required for argument 2')
enddef

def Test_prop_list()
  CheckDefAndScriptFailure2(['prop_list("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['prop_list(1, [])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 2')
enddef

def Test_prop_remove()
  CheckDefAndScriptFailure2(['prop_remove([])'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 1')
  CheckDefAndScriptFailure2(['prop_remove({}, "a")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['prop_remove({}, 1, "b")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
enddef

def Test_prop_type_add()
  CheckDefAndScriptFailure2(['prop_type_add({"a": 10}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['prop_type_add("a", "b")'], 'E1013: Argument 2: type mismatch, expected dict<any> but got string', 'E1206: Dictionary required for argument 2')
enddef

def Test_prop_type_change()
  CheckDefAndScriptFailure2(['prop_type_change({"a": 10}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['prop_type_change("a", "b")'], 'E1013: Argument 2: type mismatch, expected dict<any> but got string', 'E1206: Dictionary required for argument 2')
enddef

def Test_prop_type_delete()
  CheckDefAndScriptFailure2(['prop_type_delete({"a": 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['prop_type_delete({"a": 10}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['prop_type_delete("a", "b")'], 'E1013: Argument 2: type mismatch, expected dict<any> but got string', 'E1206: Dictionary required for argument 2')
enddef

def Test_prop_type_get()
  CheckDefAndScriptFailure2(['prop_type_get({"a": 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['prop_type_get({"a": 10}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['prop_type_get("a", "b")'], 'E1013: Argument 2: type mismatch, expected dict<any> but got string', 'E1206: Dictionary required for argument 2')
enddef

def Test_prop_type_list()
  CheckDefAndScriptFailure2(['prop_type_list(["a"])'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<string>', 'E1206: Dictionary required for argument 1')
  CheckDefAndScriptFailure2(['prop_type_list(2)'], 'E1013: Argument 1: type mismatch, expected dict<any> but got number', 'E1206: Dictionary required for argument 1')
enddef

def Test_py3eval()
  if !has('python3')
    CheckFeature python3
  endif
  CheckDefAndScriptFailure2(['py3eval([2])'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1174: String required for argument 1')
enddef

def Test_pyeval()
  if !has('python')
    CheckFeature python
  endif
  CheckDefAndScriptFailure2(['pyeval([2])'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1174: String required for argument 1')
enddef

def Test_pyxeval()
  if !has('python') && !has('python3')
    CheckFeature python
  endif
  CheckDefAndScriptFailure2(['pyxeval([2])'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1174: String required for argument 1')
enddef

def Test_rand()
  CheckDefAndScriptFailure2(['rand(10)'], 'E1013: Argument 1: type mismatch, expected list<number> but got number', 'E1211: List required for argument 1')
  CheckDefFailure(['rand(["a"])'], 'E1013: Argument 1: type mismatch, expected list<number> but got list<string>')
  assert_true(rand() >= 0)
  assert_true(rand(srand()) >= 0)
enddef

def Test_range()
  CheckDefAndScriptFailure2(['range("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['range(10, "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['range(10, 20, "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
enddef

def Test_readdir()
  eval expand('sautest')->readdir((e) => e[0] !=# '.')
  eval expand('sautest')->readdirex((e) => e.name[0] !=# '.')
  CheckDefAndScriptFailure2(['readdir(["a"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['readdir("a", "1", [3])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 3')
enddef

def Test_readdirex()
  CheckDefAndScriptFailure2(['readdirex(["a"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['readdirex("a", "1", [3])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 3')
enddef

def Test_readblob()
  var blob = 0z12341234
  writefile(blob, 'Xreadblob')
  var read: blob = readblob('Xreadblob')
  assert_equal(blob, read)

  var lines =<< trim END
      var read: list<string> = readblob('Xreadblob')
  END
  CheckDefAndScriptFailure(lines, 'E1012: Type mismatch; expected list<string> but got blob', 1)
  delete('Xreadblob')
enddef

def Test_readfile()
  var text = ['aaa', 'bbb', 'ccc']
  writefile(text, 'Xreadfile')
  var read: list<string> = readfile('Xreadfile')
  assert_equal(text, read)

  var lines =<< trim END
      var read: dict<string> = readfile('Xreadfile')
  END
  CheckDefAndScriptFailure(lines, 'E1012: Type mismatch; expected dict<string> but got list<string>', 1)
  delete('Xreadfile')

  CheckDefAndScriptFailure2(['readfile("a", 0z10)'], 'E1013: Argument 2: type mismatch, expected string but got blob', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['readfile("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
enddef

def Test_reduce()
  CheckDefAndScriptFailure2(['reduce({a: 10}, "1")'], 'E1013: Argument 1: type mismatch, expected list<any> but got dict<number>', 'E897: List or Blob required')
  assert_equal(6, [1, 2, 3]->reduce((r, c) => r + c, 0))
  assert_equal(11, 0z0506->reduce((r, c) => r + c, 0))
enddef

def Test_reltime()
  CheckFeature reltime

  CheckDefExecAndScriptFailure(['[]->reltime()'], 'E474:')
  CheckDefExecAndScriptFailure(['[]->reltime([])'], 'E474:')

  CheckDefAndScriptFailure2(['reltime("x")'], 'E1013: Argument 1: type mismatch, expected list<number> but got string', 'E1211: List required for argument 1')
  CheckDefFailure(['reltime(["x", "y"])'], 'E1013: Argument 1: type mismatch, expected list<number> but got list<string>')
  CheckDefAndScriptFailure2(['reltime([1, 2], 10)'], 'E1013: Argument 2: type mismatch, expected list<number> but got number', 'E1211: List required for argument 2')
  CheckDefFailure(['reltime([1, 2], ["a", "b"])'], 'E1013: Argument 2: type mismatch, expected list<number> but got list<string>')
  var start: list<any> = reltime()
  assert_true(type(reltime(start)) == v:t_list)
  var end: list<any> = reltime()
  assert_true(type(reltime(start, end)) == v:t_list)
enddef

def Test_reltimefloat()
  CheckFeature reltime

  CheckDefExecAndScriptFailure(['[]->reltimefloat()'], 'E474:')

  CheckDefAndScriptFailure2(['reltimefloat("x")'], 'E1013: Argument 1: type mismatch, expected list<number> but got string', 'E1211: List required for argument 1')
  CheckDefFailure(['reltimefloat([1.1])'], 'E1013: Argument 1: type mismatch, expected list<number> but got list<float>')
  assert_true(type(reltimefloat(reltime())) == v:t_float)
enddef

def Test_reltimestr()
  CheckFeature reltime

  CheckDefExecAndScriptFailure(['[]->reltimestr()'], 'E474:')

  CheckDefAndScriptFailure2(['reltimestr(true)'], 'E1013: Argument 1: type mismatch, expected list<number> but got bool', 'E1211: List required for argument 1')
  CheckDefFailure(['reltimestr([true])'], 'E1013: Argument 1: type mismatch, expected list<number> but got list<bool>')
  assert_true(type(reltimestr(reltime())) == v:t_string)
enddef

def Test_remote_expr()
  CheckFeature clientserver
  CheckEnv DISPLAY
  CheckDefAndScriptFailure2(['remote_expr(1, "b")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['remote_expr("a", 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['remote_expr("a", "b", 3)'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E1174: String required for argument 3')
  CheckDefAndScriptFailure2(['remote_expr("a", "b", "c", "d")'], 'E1013: Argument 4: type mismatch, expected number but got string', 'E1210: Number required for argument 4')
enddef

def Test_remote_foreground()
  CheckFeature clientserver
  # remote_foreground() doesn't fail on MS-Windows
  CheckNotMSWindows
  CheckEnv DISPLAY

  CheckDefAndScriptFailure2(['remote_foreground(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  assert_fails('remote_foreground("NonExistingServer")', 'E241:')
enddef

def Test_remote_peek()
  CheckFeature clientserver
  CheckEnv DISPLAY
  CheckDefAndScriptFailure2(['remote_peek(0z10)'], 'E1013: Argument 1: type mismatch, expected string but got blob', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['remote_peek("a5b6c7", [1])'], 'E1013: Argument 2: type mismatch, expected string but got list<number>', 'E1174: String required for argument 2')
enddef

def Test_remote_read()
  CheckFeature clientserver
  CheckEnv DISPLAY
  CheckDefAndScriptFailure2(['remote_read(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['remote_read("a", "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_remote_send()
  CheckFeature clientserver
  CheckEnv DISPLAY
  CheckDefAndScriptFailure2(['remote_send(1, "b")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['remote_send("a", 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['remote_send("a", "b", 3)'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E1174: String required for argument 3')
enddef

def Test_remote_startserver()
  CheckFeature clientserver
  CheckEnv DISPLAY
  CheckDefAndScriptFailure2(['remote_startserver({})'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>', 'E1174: String required for argument 1')
enddef

def Test_remove_const_list()
  var l: list<number> = [1, 2, 3, 4]
  assert_equal([1, 2], remove(l, 0, 1))
  assert_equal([3, 4], l)
enddef

def Test_remove()
  CheckDefAndScriptFailure2(['remove("a", 1)'], 'E1013: Argument 1: type mismatch, expected list<any> but got string', 'E1228: List or Dictionary or Blob required for argument 1')
  CheckDefAndScriptFailure2(['remove([], "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['remove([], 1, "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  CheckDefAndScriptFailure2(['remove({}, 1.1)'], 'E1013: Argument 2: type mismatch, expected string but got float', 'E1220: String or Number required for argument 2')
  CheckDefAndScriptFailure2(['remove(0z10, "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['remove(0z20, 1, "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  var l: any = [1, 2, 3, 4]
  remove(l, 1)
  assert_equal([1, 3, 4], l)
  remove(l, 0, 1)
  assert_equal([4], l)
  var b: any = 0z1234.5678.90
  remove(b, 1)
  assert_equal(0z1256.7890, b)
  remove(b, 1, 2)
  assert_equal(0z1290, b)
  var d: any = {a: 10, b: 20, c: 30}
  remove(d, 'b')
  assert_equal({a: 10, c: 30}, d)
  var d2: any = {1: 'a', 2: 'b', 3: 'c'}
  remove(d2, 2)
  assert_equal({1: 'a', 3: 'c'}, d2)
enddef

def Test_remove_return_type()
  var l = remove({one: [1, 2], two: [3, 4]}, 'one')
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(3)
enddef

def Test_rename()
  CheckDefAndScriptFailure2(['rename(1, "b")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['rename("a", 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
enddef

def Test_repeat()
  CheckDefAndScriptFailure2(['repeat(1.1, 2)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E1224: String or List required for argument 1')
  CheckDefAndScriptFailure2(['repeat({a: 10}, 2)'], 'E1013: Argument 1: type mismatch, expected string but got dict<', 'E1224: String or List required for argument 1')
  assert_equal('aaa', repeat('a', 3))
  assert_equal('111', repeat(1, 3))
  assert_equal([1, 1, 1], repeat([1], 3))
enddef

def Test_resolve()
  CheckDefAndScriptFailure2(['resolve([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1174: String required for argument 1')
  assert_equal('SomeFile', resolve('SomeFile'))
enddef

def Test_reverse()
  CheckDefAndScriptFailure2(['reverse(10)'], 'E1013: Argument 1: type mismatch, expected list<any> but got number', 'E1226: String or List required for argument 1')
  CheckDefAndScriptFailure2(['reverse("abc")'], 'E1013: Argument 1: type mismatch, expected list<any> but got string', 'E1226: String or List required for argument 1')
enddef

def Test_reverse_return_type()
  var l = reverse([1, 2, 3])
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(6)
enddef

def Test_rubyeval()
  if !has('ruby')
    CheckFeature ruby
  endif
  CheckDefAndScriptFailure2(['rubyeval([2])'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1174: String required for argument 1')
enddef

def Test_screenattr()
  CheckDefAndScriptFailure2(['screenattr("x", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['screenattr(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_screenchar()
  CheckDefAndScriptFailure2(['screenchar("x", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['screenchar(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_screenchars()
  CheckDefAndScriptFailure2(['screenchars("x", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['screenchars(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_screenpos()
  CheckDefAndScriptFailure2(['screenpos("a", 1, 1)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['screenpos(1, "b", 1)'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['screenpos(1, 1, "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  assert_equal({col: 1, row: 1, endcol: 1, curscol: 1}, screenpos(1, 1, 1))
enddef

def Test_screenstring()
  CheckDefAndScriptFailure2(['screenstring("x", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['screenstring(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_search()
  new
  setline(1, ['foo', 'bar'])
  var val = 0
  # skip expr returns boolean
  search('bar', 'W', 0, 0, () => val == 1)->assert_equal(2)
  :1
  search('bar', 'W', 0, 0, () => val == 0)->assert_equal(0)
  # skip expr returns number, only 0 and 1 are accepted
  :1
  search('bar', 'W', 0, 0, () => 0)->assert_equal(2)
  :1
  search('bar', 'W', 0, 0, () => 1)->assert_equal(0)
  assert_fails("search('bar', '', 0, 0, () => -1)", 'E1023:')
  assert_fails("search('bar', '', 0, 0, () => -1)", 'E1023:')

  setline(1, "find this word")
  normal gg
  var col = 7
  assert_equal(1, search('this', '', 0, 0, 'col(".") > col'))
  normal 0
  assert_equal([1, 6], searchpos('this', '', 0, 0, 'col(".") > col'))

  col = 5
  normal 0
  assert_equal(0, search('this', '', 0, 0, 'col(".") > col'))
  normal 0
  assert_equal([0, 0], searchpos('this', '', 0, 0, 'col(".") > col'))
  bwipe!
  CheckDefAndScriptFailure2(['search(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['search("a", 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['search("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  CheckDefAndScriptFailure2(['search("a", "b", 3, "d")'], 'E1013: Argument 4: type mismatch, expected number but got string', 'E1210: Number required for argument 4')
enddef

def Test_searchcount()
  new
  setline(1, "foo bar")
  :/foo
  searchcount({recompute: true})
      ->assert_equal({
          exact_match: 1,
          current: 1,
          total: 1,
          maxcount: 99,
          incomplete: 0})
  bwipe!
  CheckDefAndScriptFailure2(['searchcount([1])'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 1')
enddef

def Test_searchdecl()
  searchdecl('blah', true, true)->assert_equal(1)
  CheckDefAndScriptFailure2(['searchdecl(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['searchdecl("a", 2)'], 'E1013: Argument 2: type mismatch, expected bool but got number', 'E1212: Bool required for argument 2')
  CheckDefAndScriptFailure2(['searchdecl("a", true, 2)'], 'E1013: Argument 3: type mismatch, expected bool but got number', 'E1212: Bool required for argument 3')
enddef

def Test_searchpair()
  new
  setline(1, "here { and } there")

  normal f{
  var col = 15
  assert_equal(1, searchpair('{', '', '}', '', 'col(".") > col'))
  assert_equal(12, col('.'))
  normal 0f{
  assert_equal([1, 12], searchpairpos('{', '', '}', '', 'col(".") > col'))

  col = 8
  normal 0f{
  assert_equal(0, searchpair('{', '', '}', '', 'col(".") > col'))
  assert_equal(6, col('.'))
  normal 0f{
  assert_equal([0, 0], searchpairpos('{', '', '}', '', 'col(".") > col'))

  var lines =<< trim END
      vim9script
      setline(1, '()')
      normal gg
      def Fail()
        try
          searchpairpos('(', '', ')', 'nW', '[0]->map("")')
        catch
          g:caught = 'yes'
        endtry
      enddef
      Fail()
  END
  CheckScriptSuccess(lines)
  assert_equal('yes', g:caught)
  unlet g:caught
  bwipe!

  lines =<< trim END
      echo searchpair("a", "b", "c", "d", "f", 33)
  END
  CheckDefAndScriptFailure2(lines, 'E1001: Variable not found: f', 'E475: Invalid argument: d')

  CheckDefAndScriptFailure2(['searchpair(1, "b", "c")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['searchpair("a", 2, "c")'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['searchpair("a", "b", 3)'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E1174: String required for argument 3')
  CheckDefAndScriptFailure2(['searchpair("a", "b", "c", 4)'], 'E1013: Argument 4: type mismatch, expected string but got number', 'E1174: String required for argument 4')
  CheckDefAndScriptFailure2(['searchpair("a", "b", "c", "r", "1", "f")'], 'E1013: Argument 6: type mismatch, expected number but got string', 'E1210: Number required for argument 6')
  CheckDefAndScriptFailure2(['searchpair("a", "b", "c", "r", "1", 3, "g")'], 'E1013: Argument 7: type mismatch, expected number but got string', 'E1210: Number required for argument 7')
enddef

def Test_searchpos()
  CheckDefAndScriptFailure2(['searchpos(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['searchpos("a", 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['searchpos("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  CheckDefAndScriptFailure2(['searchpos("a", "b", 3, "d")'], 'E1013: Argument 4: type mismatch, expected number but got string', 'E1210: Number required for argument 4')
enddef

def Test_server2client()
  CheckFeature clientserver
  CheckEnv DISPLAY
  CheckDefAndScriptFailure2(['server2client(10, "b")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['server2client("a", 10)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
enddef

def Test_shellescape()
  CheckDefAndScriptFailure2(['shellescape(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['shellescape("a", 2)'], 'E1013: Argument 2: type mismatch, expected bool but got number', 'E1212: Bool required for argument 2')
enddef

def Test_set_get_bufline()
  # similar to Test_setbufline_getbufline()
  var lines =<< trim END
      new
      var b = bufnr('%')
      hide
      assert_equal(0, setbufline(b, 1, ['foo', 'bar']))
      assert_equal(['foo'], getbufline(b, 1))
      assert_equal(['bar'], getbufline(b, '$'))
      assert_equal(['foo', 'bar'], getbufline(b, 1, 2))
      exe "bd!" b
      assert_equal([], getbufline(b, 1, 2))

      split Xtest
      setline(1, ['a', 'b', 'c'])
      b = bufnr('%')
      wincmd w

      assert_equal(1, setbufline(b, 5, 'x'))
      assert_equal(1, setbufline(b, 5, ['x']))
      assert_equal(1, setbufline(b, 5, []))
      assert_equal(1, setbufline(b, 5, test_null_list()))

      assert_equal(1, 'x'->setbufline(bufnr('$') + 1, 1))
      assert_equal(1, ['x']->setbufline(bufnr('$') + 1, 1))
      assert_equal(1, []->setbufline(bufnr('$') + 1, 1))
      assert_equal(1, test_null_list()->setbufline(bufnr('$') + 1, 1))

      assert_equal(['a', 'b', 'c'], getbufline(b, 1, '$'))

      assert_equal(0, setbufline(b, 4, ['d', 'e']))
      assert_equal(['c'], b->getbufline(3))
      assert_equal(['d'], getbufline(b, 4))
      assert_equal(['e'], getbufline(b, 5))
      assert_equal([], getbufline(b, 6))
      assert_equal([], getbufline(b, 2, 1))

      if has('job')
        setbufline(b, 2, [function('eval'), {key: 123}, string(test_null_job())])
        assert_equal(["function('eval')",
                        "{'key': 123}",
                        "no process"],
                        getbufline(b, 2, 4))
      endif

      exe 'bwipe! ' .. b
  END
  CheckDefAndScriptSuccess(lines)
enddef

def Test_setbufvar()
  setbufvar(bufnr('%'), '&syntax', 'vim')
  &syntax->assert_equal('vim')
  setbufvar(bufnr('%'), '&ts', 16)
  &ts->assert_equal(16)
  setbufvar(bufnr('%'), '&ai', true)
  &ai->assert_equal(true)
  setbufvar(bufnr('%'), '&ft', 'filetype')
  &ft->assert_equal('filetype')

  settabwinvar(1, 1, '&syntax', 'vam')
  &syntax->assert_equal('vam')
  settabwinvar(1, 1, '&ts', 15)
  &ts->assert_equal(15)
  setlocal ts=8
  settabwinvar(1, 1, '&list', false)
  &list->assert_equal(false)
  settabwinvar(1, 1, '&list', true)
  &list->assert_equal(true)
  setlocal list&

  setbufvar('%', 'myvar', 123)
  getbufvar('%', 'myvar')->assert_equal(123)

  CheckDefAndScriptFailure2(['setbufvar(true, "v", 3)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['setbufvar(1, 2, 3)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
enddef

def Test_setbufline()
  new
  var bnum = bufnr('%')
  :wincmd w
  setbufline(bnum, 1, range(1, 3))
  setbufline(bnum, 4, 'one')
  setbufline(bnum, 5, 10)
  setbufline(bnum, 6, ['two', 11])
  assert_equal(['1', '2', '3', 'one', '10', 'two', '11'], getbufline(bnum, 1, '$'))
  CheckDefAndScriptFailure2(['setbufline([1], 1, "x")'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['setbufline(1, [1], "x")'], 'E1013: Argument 2: type mismatch, expected string but got list<number>', 'E1220: String or Number required for argument 2')
  CheckDefAndScriptFailure2(['setbufline(1, 1, {"a": 10})'], 'E1013: Argument 3: type mismatch, expected string but got dict<number>', 'E1224: String or List required for argument 3')
  bnum->bufwinid()->win_gotoid()
  bw!
enddef

def Test_setcellwidths()
  CheckDefAndScriptFailure2(['setcellwidths(1)'], 'E1013: Argument 1: type mismatch, expected list<any> but got number', 'E1211: List required for argument 1')
  CheckDefAndScriptFailure2(['setcellwidths({"a": 10})'], 'E1013: Argument 1: type mismatch, expected list<any> but got dict<number>', 'E1211: List required for argument 1')
enddef

def Test_setcharpos()
  CheckDefAndScriptFailure2(['setcharpos(1, [])'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefFailure(['setcharpos(".", ["a"])'], 'E1013: Argument 2: type mismatch, expected list<number> but got list<string>')
  CheckDefAndScriptFailure2(['setcharpos(".", 1)'], 'E1013: Argument 2: type mismatch, expected list<number> but got number', 'E1211: List required for argument 2')
enddef

def Test_setcharsearch()
  CheckDefAndScriptFailure2(['setcharsearch("x")'], 'E1013: Argument 1: type mismatch, expected dict<any> but got string', 'E1206: Dictionary required for argument 1')
  CheckDefAndScriptFailure2(['setcharsearch([])'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 1')
  var d: dict<any> = {char: 'x', forward: 1, until: 1}
  setcharsearch(d)
  assert_equal(d, getcharsearch())
enddef

def Test_setcmdpos()
  CheckDefAndScriptFailure2(['setcmdpos("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_setcursorcharpos()
  CheckDefAndScriptFailure2(['setcursorcharpos(0z10, 1)'], 'E1013: Argument 1: type mismatch, expected number but got blob', 'E1224: String or List required for argument 1')
  CheckDefAndScriptFailure2(['setcursorcharpos(1, "2")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['setcursorcharpos(1, 2, "3")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
enddef

def Test_setenv()
  CheckDefAndScriptFailure2(['setenv(1, 2)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
enddef

def Test_setfperm()
  CheckDefAndScriptFailure2(['setfperm(1, "b")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['setfperm("a", 0z10)'], 'E1013: Argument 2: type mismatch, expected string but got blob', 'E1174: String required for argument 2')
enddef

def Test_setline()
  new
  setline(1, range(1, 4))
  assert_equal(['1', '2', '3', '4'], getline(1, '$'))
  setline(1, ['a', 'b', 'c', 'd'])
  assert_equal(['a', 'b', 'c', 'd'], getline(1, '$'))
  setline(1, 'one')
  assert_equal(['one', 'b', 'c', 'd'], getline(1, '$'))
  setline(1, 10)
  assert_equal(['10', 'b', 'c', 'd'], getline(1, '$'))
  CheckDefAndScriptFailure2(['setline([1], "x")'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1220: String or Number required for argument 1')
  bw!
enddef

def Test_setloclist()
  var items = [{filename: '/tmp/file', lnum: 1, valid: true}]
  var what = {items: items}
  setqflist([], ' ', what)
  setloclist(0, [], ' ', what)
  CheckDefAndScriptFailure2(['setloclist("1", [])'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['setloclist(1, 2)'], 'E1013: Argument 2: type mismatch, expected list<any> but got number', 'E1211: List required for argument 2')
  CheckDefAndScriptFailure2(['setloclist(1, [], 3)'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E1174: String required for argument 3')
  CheckDefAndScriptFailure2(['setloclist(1, [], "a", [])'], 'E1013: Argument 4: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 4')
enddef

def Test_setmatches()
  CheckDefAndScriptFailure2(['setmatches({})'], 'E1013: Argument 1: type mismatch, expected list<any> but got dict<unknown>', 'E1211: List required for argument 1')
  CheckDefAndScriptFailure2(['setmatches([], "1")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_setpos()
  CheckDefAndScriptFailure2(['setpos(1, [])'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefFailure(['setpos(".", ["a"])'], 'E1013: Argument 2: type mismatch, expected list<number> but got list<string>')
  CheckDefAndScriptFailure2(['setpos(".", 1)'], 'E1013: Argument 2: type mismatch, expected list<number> but got number', 'E1211: List required for argument 2')
enddef

def Test_setqflist()
  CheckDefAndScriptFailure2(['setqflist(1, "")'], 'E1013: Argument 1: type mismatch, expected list<any> but got number', 'E1211: List required for argument 1')
  CheckDefAndScriptFailure2(['setqflist([], 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['setqflist([], "", [])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 3')
enddef

def Test_setreg()
  setreg('a', ['aaa', 'bbb', 'ccc'])
  var reginfo = getreginfo('a')
  setreg('a', reginfo)
  getreginfo('a')->assert_equal(reginfo)
  assert_fails('setreg("ab", 0)', 'E1162:')
  CheckDefAndScriptFailure2(['setreg(1, "b")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['setreg("a", "b", 3)'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E1174: String required for argument 3')
enddef 

def Test_settabvar()
  CheckDefAndScriptFailure2(['settabvar("a", "b", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['settabvar(1, 2, "c")'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
enddef

def Test_settabwinvar()
  CheckDefAndScriptFailure2(['settabwinvar("a", 2, "c", true)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['settabwinvar(1, "b", "c", [])'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['settabwinvar(1, 1, 3, {})'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E1174: String required for argument 3')
enddef

def Test_settagstack()
  CheckDefAndScriptFailure2(['settagstack(true, {})'], 'E1013: Argument 1: type mismatch, expected number but got bool', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['settagstack(1, [1])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 2')
  CheckDefAndScriptFailure2(['settagstack(1, {}, 2)'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E1174: String required for argument 3')
enddef

def Test_setwinvar()
  CheckDefAndScriptFailure2(['setwinvar("a", "b", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['setwinvar(1, 2, "c")'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
enddef

def Test_sha256()
  CheckDefAndScriptFailure2(['sha256(100)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['sha256(0zABCD)'], 'E1013: Argument 1: type mismatch, expected string but got blob', 'E1174: String required for argument 1')
  assert_equal('ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad', sha256('abc'))
enddef

def Test_shiftwidth()
  CheckDefAndScriptFailure2(['shiftwidth("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_sign_define()
  CheckDefAndScriptFailure2(['sign_define({"a": 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1222: String or List required for argument 1')
  CheckDefAndScriptFailure2(['sign_define({"a": 10}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1222: String or List required for argument 1')
  CheckDefAndScriptFailure2(['sign_define("a", ["b"])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<string>', 'E1206: Dictionary required for argument 2')
enddef

def Test_sign_getdefined()
  CheckDefAndScriptFailure2(['sign_getdefined(["x"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['sign_getdefined(2)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
enddef

def Test_sign_getplaced()
  CheckDefAndScriptFailure2(['sign_getplaced(["x"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['sign_getplaced(1, ["a"])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<string>', 'E1206: Dictionary required for argument 2')
  CheckDefAndScriptFailure2(['sign_getplaced("a", 1.1)'], 'E1013: Argument 2: type mismatch, expected dict<any> but got float', 'E1206: Dictionary required for argument 2')
enddef

def Test_sign_jump()
  CheckDefAndScriptFailure2(['sign_jump("a", "b", "c")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['sign_jump(1, 2, 3)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['sign_jump(1, "b", true)'], 'E1013: Argument 3: type mismatch, expected string but got bool', 'E1220: String or Number required for argument 3')
enddef

def Test_sign_place()
  CheckDefAndScriptFailure2(['sign_place("a", "b", "c", "d")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['sign_place(1, 2, "c", "d")'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['sign_place(1, "b", 3, "d")'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E1174: String required for argument 3')
  CheckDefAndScriptFailure2(['sign_place(1, "b", "c", 1.1)'], 'E1013: Argument 4: type mismatch, expected string but got float', 'E1220: String or Number required for argument 4')
  CheckDefAndScriptFailure2(['sign_place(1, "b", "c", "d", [1])'], 'E1013: Argument 5: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 5')
enddef

def Test_sign_placelist()
  CheckDefAndScriptFailure2(['sign_placelist("x")'], 'E1013: Argument 1: type mismatch, expected list<any> but got string', 'E1211: List required for argument 1')
  CheckDefAndScriptFailure2(['sign_placelist({"a": 10})'], 'E1013: Argument 1: type mismatch, expected list<any> but got dict<number>', 'E1211: List required for argument 1')
enddef

def Test_sign_undefine()
  CheckDefAndScriptFailure2(['sign_undefine({})'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>', 'E1222: String or List required for argument 1')
  CheckDefAndScriptFailure2(['sign_undefine([1])'], 'E1013: Argument 1: type mismatch, expected list<string> but got list<number>', 'E155: Unknown sign:')
enddef

def Test_sign_unplace()
  CheckDefAndScriptFailure2(['sign_unplace({"a": 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['sign_unplace({"a": 10}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['sign_unplace("a", ["b"])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<string>', 'E1206: Dictionary required for argument 2')
enddef

def Test_sign_unplacelist()
  CheckDefAndScriptFailure2(['sign_unplacelist("x")'], 'E1013: Argument 1: type mismatch, expected list<any> but got string', 'E1211: List required for argument 1')
  CheckDefAndScriptFailure2(['sign_unplacelist({"a": 10})'], 'E1013: Argument 1: type mismatch, expected list<any> but got dict<number>', 'E1211: List required for argument 1')
enddef

def Test_simplify()
  CheckDefAndScriptFailure2(['simplify(100)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  call assert_equal('NonExistingFile', simplify('NonExistingFile'))
enddef

def Test_slice()
  assert_equal('12345', slice('012345', 1))
  assert_equal('123', slice('012345', 1, 4))
  assert_equal('1234', slice('012345', 1, -1))
  assert_equal('1', slice('012345', 1, -4))
  assert_equal('', slice('012345', 1, -5))
  assert_equal('', slice('012345', 1, -6))

  assert_equal([1, 2, 3, 4, 5], slice(range(6), 1))
  assert_equal([1, 2, 3], slice(range(6), 1, 4))
  assert_equal([1, 2, 3, 4], slice(range(6), 1, -1))
  assert_equal([1], slice(range(6), 1, -4))
  assert_equal([], slice(range(6), 1, -5))
  assert_equal([], slice(range(6), 1, -6))

  assert_equal(0z1122334455, slice(0z001122334455, 1))
  assert_equal(0z112233, slice(0z001122334455, 1, 4))
  assert_equal(0z11223344, slice(0z001122334455, 1, -1))
  assert_equal(0z11, slice(0z001122334455, 1, -4))
  assert_equal(0z, slice(0z001122334455, 1, -5))
  assert_equal(0z, slice(0z001122334455, 1, -6))
  CheckDefAndScriptFailure2(['slice({"a": 10}, 1)'], 'E1013: Argument 1: type mismatch, expected list<any> but got dict<number>', 'E1211: List required for argument 1')
  CheckDefAndScriptFailure2(['slice([1, 2, 3], "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['slice("abc", 1, "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
enddef

def Test_spellsuggest()
  if !has('spell')
    CheckFeature spell
  else
    spellsuggest('marrch', 1, true)->assert_equal(['March'])
  endif
  CheckDefAndScriptFailure2(['spellsuggest(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['spellsuggest("a", "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['spellsuggest("a", 1, 0z01)'], 'E1013: Argument 3: type mismatch, expected bool but got blob', 'E1212: Bool required for argument 3')
enddef

def Test_sound_playevent()
  CheckFeature sound
  CheckDefAndScriptFailure2(['sound_playevent(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
enddef

def Test_sound_playfile()
  CheckFeature sound
  CheckDefAndScriptFailure2(['sound_playfile(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
enddef

def Test_sound_stop()
  CheckFeature sound
  CheckDefAndScriptFailure2(['sound_stop("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_soundfold()
  CheckDefAndScriptFailure2(['soundfold(20)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  assert_equal('abc', soundfold('abc'))
enddef

def Test_sort_return_type()
  var res: list<number>
  res = [1, 2, 3]->sort()
enddef

def Test_sort_argument()
  var lines =<< trim END
    var res = ['b', 'a', 'c']->sort('i')
    res->assert_equal(['a', 'b', 'c'])

    def Compare(a: number, b: number): number
      return a - b
    enddef
    var l = [3, 6, 7, 1, 8, 2, 4, 5]
    sort(l, Compare)
    assert_equal([1, 2, 3, 4, 5, 6, 7, 8], l)
  END
  CheckDefAndScriptSuccess(lines)
  CheckDefAndScriptFailure2(['sort("a")'], 'E1013: Argument 1: type mismatch, expected list<any> but got string', 'E1211: List required for argument 1')
  CheckDefAndScriptFailure2(['sort([1], "", [1])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 3')
enddef

def Test_spellbadword()
  CheckDefAndScriptFailure2(['spellbadword(100)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  spellbadword('good')->assert_equal(['', ''])
enddef

def Test_split()
  split('  aa  bb  ', '\W\+', true)->assert_equal(['', 'aa', 'bb', ''])
  CheckDefAndScriptFailure2(['split(1, "b")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['split("a", 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['split("a", "b", 2)'], 'E1013: Argument 3: type mismatch, expected bool but got number', 'E1212: Bool required for argument 3')
enddef

def Test_srand()
  CheckDefAndScriptFailure2(['srand("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  type(srand(100))->assert_equal(v:t_list)
enddef

def Test_state()
  CheckDefAndScriptFailure2(['state({})'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>', 'E1174: String required for argument 1')
  assert_equal('', state('a'))
enddef

def Run_str2float()
  if !has('float')
    CheckFeature float
  endif
    str2float("1.00")->assert_equal(1.00)
    str2float("2e-2")->assert_equal(0.02)

    CheckDefAndScriptFailure2(['str2float(123)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  endif
enddef

def Test_str2list()
  CheckDefAndScriptFailure2(['str2list(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['str2list("a", 2)'], 'E1013: Argument 2: type mismatch, expected bool but got number', 'E1212: Bool required for argument 2')
  assert_equal([97], str2list('a'))
  assert_equal([97], str2list('a', 1))
  assert_equal([97], str2list('a', true))
enddef

def Test_str2nr()
  str2nr("1'000'000", 10, true)->assert_equal(1000000)

  CheckDefAndScriptFailure2(['str2nr(123)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['str2nr("123", "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['str2nr("123", 10, "x")'], 'E1013: Argument 3: type mismatch, expected bool but got string', 'E1212: Bool required for argument 3')
enddef

def Test_strcharlen()
  CheckDefAndScriptFailure2(['strcharlen([1])'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1220: String or Number required for argument 1')
  "abc"->strcharlen()->assert_equal(3)
  strcharlen(99)->assert_equal(2)
enddef

def Test_strcharpart()
  CheckDefAndScriptFailure2(['strcharpart(1, 2)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['strcharpart("a", "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['strcharpart("a", 1, "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  CheckDefAndScriptFailure2(['strcharpart("a", 1, 1, 2)'], 'E1013: Argument 4: type mismatch, expected bool but got number', 'E1212: Bool required for argument 4')
enddef

def Test_strchars()
  strchars("A\u20dd", true)->assert_equal(1)
  CheckDefAndScriptFailure2(['strchars(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['strchars("a", 2)'], 'E1013: Argument 2: type mismatch, expected bool but got number', 'E1212: Bool required for argument 2')
  assert_equal(3, strchars('abc'))
  assert_equal(3, strchars('abc', 1))
  assert_equal(3, strchars('abc', true))
enddef

def Test_strdisplaywidth()
  CheckDefAndScriptFailure2(['strdisplaywidth(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['strdisplaywidth("a", "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_strftime()
  CheckDefAndScriptFailure2(['strftime(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['strftime("a", "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_strgetchar()
  CheckDefAndScriptFailure2(['strgetchar(1, 1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['strgetchar("a", "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_stridx()
  CheckDefAndScriptFailure2(['stridx([1], "b")'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['stridx("a", {})'], 'E1013: Argument 2: type mismatch, expected string but got dict<unknown>', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['stridx("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
enddef

def Test_strlen()
  CheckDefAndScriptFailure2(['strlen([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1220: String or Number required for argument 1')
  "abc"->strlen()->assert_equal(3)
  strlen(99)->assert_equal(2)
enddef

def Test_strpart()
  CheckDefAndScriptFailure2(['strpart(1, 2)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['strpart("a", "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['strpart("a", 1, "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  CheckDefAndScriptFailure2(['strpart("a", 1, 1, 2)'], 'E1013: Argument 4: type mismatch, expected bool but got number', 'E1212: Bool required for argument 4')
enddef

def Test_strptime()
  CheckFunction strptime
  CheckDefAndScriptFailure2(['strptime(10, "2021")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['strptime("%Y", 2021)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  # BUG: Directly calling strptime() in this function gives an "E117: Unknown
  # function" error on MS-Windows even with the above CheckFunction call for
  # strptime().
  #assert_true(strptime('%Y', '2021') != 0)
enddef

def Test_strridx()
  CheckDefAndScriptFailure2(['strridx([1], "b")'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['strridx("a", {})'], 'E1013: Argument 2: type mismatch, expected string but got dict<unknown>', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['strridx("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
enddef

def Test_strtrans()
  CheckDefAndScriptFailure2(['strtrans(20)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  assert_equal('abc', strtrans('abc'))
enddef

def Test_strwidth()
  CheckDefAndScriptFailure2(['strwidth(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  assert_equal(4, strwidth('abcd'))
enddef

def Test_submatch()
  var pat = 'A\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)'
  var Rep = () => range(10)->mapnew((_, v) => submatch(v, true))->string()
  var actual = substitute('A123456789', pat, Rep, '')
  var expected = "[['A123456789'], ['1'], ['2'], ['3'], ['4'], ['5'], ['6'], ['7'], ['8'], ['9']]"
  actual->assert_equal(expected)
  CheckDefAndScriptFailure2(['submatch("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['submatch(1, "a")'], 'E1013: Argument 2: type mismatch, expected bool but got string', 'E1212: Bool required for argument 2')
enddef

def Test_substitute()
  var res = substitute('A1234', '\d', 'X', '')
  assert_equal('AX234', res)

  if has('job')
    assert_fails('"text"->substitute(".*", () => test_null_job(), "")', 'E908: using an invalid value as a String: job')
    assert_fails('"text"->substitute(".*", () => test_null_channel(), "")', 'E908: using an invalid value as a String: channel')
  endif
  CheckDefAndScriptFailure2(['substitute(1, "b", "1", "d")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['substitute("a", 2, "1", "d")'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['substitute("a", "b", "1", 4)'], 'E1013: Argument 4: type mismatch, expected string but got number', 'E1174: String required for argument 4')
enddef

def Test_swapinfo()
  CheckDefAndScriptFailure2(['swapinfo({})'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>', 'E1174: String required for argument 1')
  call assert_equal({error: 'Cannot open file'}, swapinfo('x'))
enddef

def Test_swapname()
  CheckDefAndScriptFailure2(['swapname([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1220: String or Number required for argument 1')
  assert_fails('swapname("NonExistingBuf")', 'E94:')
enddef

def Test_synID()
  new
  setline(1, "text")
  synID(1, 1, true)->assert_equal(0)
  bwipe!
  CheckDefAndScriptFailure2(['synID(0z10, 1, true)'], 'E1013: Argument 1: type mismatch, expected string but got blob', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['synID("a", true, false)'], 'E1013: Argument 2: type mismatch, expected number but got bool', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['synID(1, 1, 2)'], 'E1013: Argument 3: type mismatch, expected bool but got number', 'E1212: Bool required for argument 3')
enddef

def Test_synIDattr()
  CheckDefAndScriptFailure2(['synIDattr("a", "b")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['synIDattr(1, 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['synIDattr(1, "b", 3)'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E1174: String required for argument 3')
enddef

def Test_synIDtrans()
  CheckDefAndScriptFailure2(['synIDtrans("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_synconcealed()
  CheckDefAndScriptFailure2(['synconcealed(0z10, 1)'], 'E1013: Argument 1: type mismatch, expected string but got blob', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['synconcealed(1, "a")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_synstack()
  CheckDefAndScriptFailure2(['synstack(0z10, 1)'], 'E1013: Argument 1: type mismatch, expected string but got blob', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['synstack(1, "a")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_system()
  CheckDefAndScriptFailure2(['system(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['system("a", {})'], 'E1013: Argument 2: type mismatch, expected string but got dict<unknown>', 'E1224: String or List required for argument 2')
  assert_equal("123\n", system('echo 123'))
enddef

def Test_systemlist()
  CheckDefAndScriptFailure2(['systemlist(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['systemlist("a", {})'], 'E1013: Argument 2: type mismatch, expected string but got dict<unknown>', 'E1224: String or List required for argument 2')
  if has('win32')
    call assert_equal(["123\r"], systemlist('echo 123'))
  else
    call assert_equal(['123'], systemlist('echo 123'))
  endif
enddef

def Test_tabpagebuflist()
  CheckDefAndScriptFailure2(['tabpagebuflist("t")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  assert_equal([bufnr('')], tabpagebuflist())
  assert_equal([bufnr('')], tabpagebuflist(1))
enddef

def Test_tabpagenr()
  CheckDefAndScriptFailure2(['tabpagenr(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  assert_equal(1, tabpagenr('$'))
  assert_equal(1, tabpagenr())
enddef

def Test_tabpagewinnr()
  CheckDefAndScriptFailure2(['tabpagewinnr("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['tabpagewinnr(1, 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
enddef

def Test_taglist()
  CheckDefAndScriptFailure2(['taglist([1])'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['taglist("a", [2])'], 'E1013: Argument 2: type mismatch, expected string but got list<number>', 'E1174: String required for argument 2')
enddef

def Test_term_dumpload()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_dumpload({"a": 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['term_dumpload({"a": 10}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['term_dumpload("a", ["b"])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<string>', 'E1206: Dictionary required for argument 2')
enddef

def Test_term_dumpdiff()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_dumpdiff(1, "b")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['term_dumpdiff("a", 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['term_dumpdiff("a", "b", [1])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 3')
enddef

def Test_term_dumpwrite()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_dumpwrite(true, "b")'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['term_dumpwrite(1, 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['term_dumpwrite("a", "b", [1])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 3')
enddef

def Test_term_getaltscreen()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_getaltscreen(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1220: String or Number required for argument 1')
enddef

def Test_term_getansicolors()
  CheckRunVimInTerminal
  CheckFeature termguicolors
  CheckDefAndScriptFailure2(['term_getansicolors(["a"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E1220: String or Number required for argument 1')
enddef

def Test_term_getattr()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_getattr("x", "a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['term_getattr(1, 2)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
enddef

def Test_term_getcursor()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_getcursor({"a": 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1220: String or Number required for argument 1')
enddef

def Test_term_getjob()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_getjob(0z10)'], 'E1013: Argument 1: type mismatch, expected string but got blob', 'E1220: String or Number required for argument 1')
enddef

def Test_term_getline()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_getline(1.1, 1)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['term_getline(1, 1.1)'], 'E1013: Argument 2: type mismatch, expected string but got float', 'E1220: String or Number required for argument 2')
enddef

def Test_term_getscrolled()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_getscrolled(1.1)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E1220: String or Number required for argument 1')
enddef

def Test_term_getsize()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_getsize(1.1)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E1220: String or Number required for argument 1')
enddef

def Test_term_getstatus()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_getstatus(1.1)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E1220: String or Number required for argument 1')
enddef

def Test_term_gettitle()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_gettitle(1.1)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E1220: String or Number required for argument 1')
enddef

def Test_term_gettty()
  if !has('terminal')
    CheckFeature terminal
  else
    var buf = Run_shell_in_terminal({})
    term_gettty(buf, true)->assert_notequal('')
    StopShellInTerminal(buf)
  endif
  CheckDefAndScriptFailure2(['term_gettty([1])'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['term_gettty(1, 2)'], 'E1013: Argument 2: type mismatch, expected bool but got number', 'E1212: Bool required for argument 2')
enddef

def Test_term_scrape()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_scrape(1.1, 1)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['term_scrape(1, 1.1)'], 'E1013: Argument 2: type mismatch, expected string but got float', 'E1220: String or Number required for argument 2')
enddef

def Test_term_sendkeys()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_sendkeys([], "p")'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['term_sendkeys(1, [])'], 'E1013: Argument 2: type mismatch, expected string but got list<unknown>', 'E1174: String required for argument 2')
enddef

def Test_term_setansicolors()
  CheckRunVimInTerminal

  if has('termguicolors') || has('gui')
    CheckDefAndScriptFailure2(['term_setansicolors([], "p")'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1220: String or Number required for argument 1')
    CheckDefAndScriptFailure2(['term_setansicolors(10, {})'], 'E1013: Argument 2: type mismatch, expected list<any> but got dict<unknown>', 'E1211: List required for argument 2')
  else
    throw 'Skipped: Only works with termguicolors or gui feature'
  endif
enddef

def Test_term_setapi()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_setapi([], "p")'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['term_setapi(1, [])'], 'E1013: Argument 2: type mismatch, expected string but got list<unknown>', 'E1174: String required for argument 2')
enddef

def Test_term_setkill()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_setkill([], "p")'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['term_setkill(1, [])'], 'E1013: Argument 2: type mismatch, expected string but got list<unknown>', 'E1174: String required for argument 2')
enddef

def Test_term_setrestore()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_setrestore([], "p")'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['term_setrestore(1, [])'], 'E1013: Argument 2: type mismatch, expected string but got list<unknown>', 'E1174: String required for argument 2')
enddef

def Test_term_setsize()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_setsize(1.1, 2, 3)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['term_setsize(1, "2", 3)'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['term_setsize(1, 2, "3")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
enddef

def Test_term_start()
  if !has('terminal')
    CheckFeature terminal
  else
    botright new
    var winnr = winnr()
    term_start(&shell, {curwin: true})
    winnr()->assert_equal(winnr)
    bwipe!
  endif
  CheckDefAndScriptFailure2(['term_start({})'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>', 'E1222: String or List required for argument 1')
  CheckDefAndScriptFailure2(['term_start([], [])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 2')
  CheckDefAndScriptFailure2(['term_start("", "")'], 'E1013: Argument 2: type mismatch, expected dict<any> but got string', 'E1206: Dictionary required for argument 2')
enddef

def Test_term_wait()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_wait(0z10, 1)'], 'E1013: Argument 1: type mismatch, expected string but got blob', 'E1220: String or Number required for argument 1')
  CheckDefAndScriptFailure2(['term_wait(1, "a")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_test_alloc_fail()
  CheckDefAndScriptFailure2(['test_alloc_fail("a", 10, 20)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['test_alloc_fail(10, "b", 20)'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['test_alloc_fail(10, 20, "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
enddef

def Test_test_feedinput()
  CheckDefAndScriptFailure2(['test_feedinput(test_void())'], 'E1013: Argument 1: type mismatch, expected string but got void', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['test_feedinput(["a"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E1174: String required for argument 1')
enddef

def Test_test_getvalue()
  CheckDefAndScriptFailure2(['test_getvalue(1.1)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E1174: String required for argument 1')
enddef

def Test_test_gui_drop_files()
  CheckGui
  CheckDefAndScriptFailure2(['test_gui_drop_files("a", 1, 1, 0)'], 'E1013: Argument 1: type mismatch, expected list<string> but got string', 'E1211: List required for argument 1')
  CheckDefAndScriptFailure2(['test_gui_drop_files(["x"], "", 1, 0)'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['test_gui_drop_files(["x"], 1, "", 0)'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  CheckDefAndScriptFailure2(['test_gui_drop_files(["x"], 1, 1, "")'], 'E1013: Argument 4: type mismatch, expected number but got string', 'E1210: Number required for argument 4')
enddef

def Test_test_gui_mouse_event()
  CheckGui
  CheckDefAndScriptFailure2(['test_gui_mouse_event(1.1, 1, 1, 1, 1)'], 'E1013: Argument 1: type mismatch, expected number but got float', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['test_gui_mouse_event(1, "1", 1, 1, 1)'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['test_gui_mouse_event(1, 1, "1", 1, 1)'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
  CheckDefAndScriptFailure2(['test_gui_mouse_event(1, 1, 1, "1", 1)'], 'E1013: Argument 4: type mismatch, expected number but got string', 'E1210: Number required for argument 4')
  CheckDefAndScriptFailure2(['test_gui_mouse_event(1, 1, 1, 1, "1")'], 'E1013: Argument 5: type mismatch, expected number but got string', 'E1210: Number required for argument 5')
enddef

def Test_test_ignore_error()
  CheckDefAndScriptFailure2(['test_ignore_error([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1174: String required for argument 1')
  test_ignore_error('RESET')
enddef

def Test_test_option_not_set()
  CheckDefAndScriptFailure2(['test_option_not_set([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1174: String required for argument 1')
enddef

def Test_test_override()
  CheckDefAndScriptFailure2(['test_override(1, 1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['test_override("a", "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_test_scrollbar()
  CheckGui
  CheckDefAndScriptFailure2(['test_scrollbar(1, 2, 3)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['test_scrollbar("a", "b", 3)'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['test_scrollbar("a", 2, "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
enddef

def Test_test_setmouse()
  CheckDefAndScriptFailure2(['test_setmouse("a", 10)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['test_setmouse(10, "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

def Test_test_settime()
  CheckDefAndScriptFailure2(['test_settime([1])'], 'E1013: Argument 1: type mismatch, expected number but got list<number>', 'E1210: Number required for argument 1')
enddef

def Test_test_srand_seed()
  CheckDefAndScriptFailure2(['test_srand_seed([1])'], 'E1013: Argument 1: type mismatch, expected number but got list<number>', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['test_srand_seed("10")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_timer_info()
  CheckDefAndScriptFailure2(['timer_info("id")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  assert_equal([], timer_info(100))
  assert_equal([], timer_info())
enddef

def Test_timer_pause()
  CheckDefAndScriptFailure2(['timer_pause("x", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['timer_pause(1, "a")'], 'E1013: Argument 2: type mismatch, expected bool but got string', 'E1212: Bool required for argument 2')
enddef

def Test_timer_paused()
  var id = timer_start(50, () => 0)
  timer_pause(id, true)
  var info = timer_info(id)
  info[0]['paused']->assert_equal(1)
  timer_stop(id)
enddef

def Test_timer_start()
  CheckDefAndScriptFailure2(['timer_start("a", "1")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['timer_start(1, "1", [1])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 3')
enddef

def Test_timer_stop()
  CheckDefAndScriptFailure2(['timer_stop("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  assert_equal(0, timer_stop(100))
enddef

def Test_tolower()
  CheckDefAndScriptFailure2(['tolower(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
enddef

def Test_toupper()
  CheckDefAndScriptFailure2(['toupper(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
enddef

def Test_tr()
  CheckDefAndScriptFailure2(['tr(1, "a", "b")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['tr("a", 1, "b")'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['tr("a", "a", 1)'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E1174: String required for argument 3')
enddef

def Test_trim()
  CheckDefAndScriptFailure2(['trim(["a"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['trim("a", ["b"])'], 'E1013: Argument 2: type mismatch, expected string but got list<string>', 'E1174: String required for argument 2')
  CheckDefAndScriptFailure2(['trim("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1210: Number required for argument 3')
enddef

def Test_typename()
  if has('float')
    assert_equal('func([unknown], [unknown]): float', typename(function('pow')))
  endif
enddef

def Test_undofile()
  CheckDefAndScriptFailure2(['undofile(10)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  assert_equal('.abc.un~', fnamemodify(undofile('abc'), ':t'))
enddef

def Test_uniq()
  CheckDefAndScriptFailure2(['uniq("a")'], 'E1013: Argument 1: type mismatch, expected list<any> but got string', 'E1211: List required for argument 1')
  CheckDefAndScriptFailure2(['uniq([1], "", [1])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 3')
enddef

def Test_values()
  CheckDefAndScriptFailure2(['values([])'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 1')
  assert_equal([], {}->values())
  assert_equal(['sun'], {star: 'sun'}->values())
enddef

def Test_virtcol()
  CheckDefAndScriptFailure2(['virtcol(1.1)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E1222: String or List required for argument 1')
  new
  setline(1, ['abcdefgh'])
  cursor(1, 4)
  assert_equal(4, virtcol('.'))
  assert_equal(4, virtcol([1, 4]))
  assert_equal(9, virtcol([1, '$']))
  assert_equal(0, virtcol([10, '$']))
  bw!
enddef

def Test_visualmode()
  CheckDefAndScriptFailure2(['visualmode("1")'], 'E1013: Argument 1: type mismatch, expected bool but got string', 'E1212: Bool required for argument 1')
  CheckDefAndScriptFailure2(['visualmode(2)'], 'E1013: Argument 1: type mismatch, expected bool but got number', 'E1212: Bool required for argument 1')
enddef

def Test_win_execute()
  assert_equal("\n" .. winnr(), win_execute(win_getid(), 'echo winnr()'))
  assert_equal("\n" .. winnr(), 'echo winnr()'->win_execute(win_getid()))
  assert_equal("\n" .. winnr(), win_execute(win_getid(), 'echo winnr()', 'silent'))
  assert_equal('', win_execute(342343, 'echo winnr()'))
  CheckDefAndScriptFailure2(['win_execute("a", "b", "c")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['win_execute(1, 2, "c")'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E1222: String or List required for argument 2')
  CheckDefAndScriptFailure2(['win_execute(1, "b", 3)'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E1174: String required for argument 3')
enddef

def Test_win_findbuf()
  CheckDefAndScriptFailure2(['win_findbuf("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  assert_equal([], win_findbuf(1000))
  assert_equal([win_getid()], win_findbuf(bufnr('')))
enddef

def Test_win_getid()
  CheckDefAndScriptFailure2(['win_getid(".")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['win_getid(1, ".")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  assert_equal(win_getid(), win_getid(1, 1))
enddef

def Test_win_gettype()
  CheckDefAndScriptFailure2(['win_gettype("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_win_gotoid()
  CheckDefAndScriptFailure2(['win_gotoid("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_win_id2tabwin()
  CheckDefAndScriptFailure2(['win_id2tabwin("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_win_id2win()
  CheckDefAndScriptFailure2(['win_id2win("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_win_screenpos()
  CheckDefAndScriptFailure2(['win_screenpos("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_win_splitmove()
  split
  win_splitmove(1, 2, {vertical: true, rightbelow: true})
  close
  CheckDefAndScriptFailure2(['win_splitmove("a", 2)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['win_splitmove(1, "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
  CheckDefAndScriptFailure2(['win_splitmove(1, 2, [])'], 'E1013: Argument 3: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 3')
enddef

def Test_winbufnr()
  CheckDefAndScriptFailure2(['winbufnr("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_winheight()
  CheckDefAndScriptFailure2(['winheight("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_winlayout()
  CheckDefAndScriptFailure2(['winlayout("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_winnr()
  CheckDefAndScriptFailure2(['winnr([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E1174: String required for argument 1')
  assert_equal(1, winnr())
  assert_equal(1, winnr('$'))
enddef

def Test_winrestcmd()
  split
  var cmd = winrestcmd()
  wincmd _
  exe cmd
  assert_equal(cmd, winrestcmd())
  close
enddef

def Test_winrestview()
  CheckDefAndScriptFailure2(['winrestview([])'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<unknown>', 'E1206: Dictionary required for argument 1')
  :%d _
  setline(1, 'Hello World')
  winrestview({lnum: 1, col: 6})
  assert_equal([1, 7], [line('.'), col('.')])
enddef

def Test_winsaveview()
  var view: dict<number> = winsaveview()

  var lines =<< trim END
      var view: list<number> = winsaveview()
  END
  CheckDefAndScriptFailure(lines, 'E1012: Type mismatch; expected list<number> but got dict<number>', 1)
enddef

def Test_winwidth()
  CheckDefAndScriptFailure2(['winwidth("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
enddef

def Test_xor()
  CheckDefAndScriptFailure2(['xor("x", 0x2)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1210: Number required for argument 1')
  CheckDefAndScriptFailure2(['xor(0x1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1210: Number required for argument 2')
enddef

" vim: ts=8 sw=2 sts=2 expandtab tw=80 fdm=marker
