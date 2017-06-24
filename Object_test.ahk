#Include Object.ahk

; gosub TestHasProp
; gosub TestHasMethod
; gosub TestDefineProp
; gosub TestDefineMeth
; gosub TestClass
; gosub TestSubClass
; gosub TestBase
; gosub TestIs
; gosub TestIs2
; gosub TestCurly
; gosub TestSquare
; gosub TestArrayFor
; gosub TestArrayLength
gosub TestArrayIndex
ExitApp

TestArrayIndex:
Test x := ['A','B','C']
Test x[1] x[2] x[3] x[-1] x[-2] x[-3] (x[-4] || '.') (x[0] || '.')
Test (x[0] := 'D') x[-1] x[4] ' ' x.length
Test (x[-2] := 'c') x[3]
return

TestArrayLength:
Test ['A','B','C'].length
Test ['A',,'B',,'C'].length
x := ['A','B','C']
Test (x.Length := 2) x.HasKey(3) x.Length ' :' x[3]
Test (x.Length := 4) x.HasKey(4) x.Length ' :' x[4]
Test x.Push('D') '=' x[4] ',' x[5] ' #' x.Length
Test x.RemoveAt(5) ' ' x.Length
Test x.RemoveAt(10) ' ' x.Length
Test x.InsertAt(10, 'X') ' ' x.Length ' ' x[10]
return

TestArrayFor:
x := [10, 20,, 40]
x.prop := 42
D('for v in x'), s := ''
for v in x
    s .= ' ' A_Index ':' v
D s
D('for k, v in x'), s := ''
for k, v in x
    s .= ' ' k ':' v
D s
Test x.RemoveAt(2,1*2)
Test x.length := 4
D('for v in x'), s := ''
for v in x
    s .= ' ' A_Index ':' v
D s
D('for k, v in x'), s := ''
for k, v in x
    s .= ' ' k ':' v
D s
return

TestSquare:
x := [10, 20,, 40]
Test (x is Array) (x is Object)
Test x.HasKey(1) x.HasProperty(1) x.HasProperty(3) ObjHasKey(x, 1)
Test x.HasProperty('Length') x.HasMethod('Length') x.HasMethod('MaxIndex')
Test x.1 x[1] x.2 x[2] ' ' x.Length
return

TestCurly:
x := {a: 1, b: 2}
Test (x is Arrax) (x is Object)
Test x.HasKey('a') x.HasProperty('a') ObjHasKey(x, 'a')
Test x.a x.b x['a']
return

TestIs2:
x := new Object, y := new Object
Test x.is(Object) x.is('object') Object.is(Object) x.is(y)
Test (new TestClass).is(TestClass)
Test (new TestClass).is(Object)
Test TestClass.is(Object) TestSubClass.is(TestClass)
Test TestClass.is(Class) (new TestClass).is(Class)
return

TestIs:
x := new Object, y := new Object
Test (x is Object) (x is 'object') (Object is Object) (x is y)
Test (new TestClass) is TestClass
Test (new TestClass) is Object
Test (TestClass is Object) (TestSubClass is TestClass)
Test (TestClass is Class) (new TestClass is Class)
return

TestBase:
Test ({}.base = Object) ([].base = Array)
Test (new Object).base = Object
Test (new TestClass).base = TestClass
Test TestClass.base = Object
try
    Test (TestClass.base := 1) " FAIL"
catch Exception
    D "(TestClass.base := 1) => " Exception.message
return

TestClass:
x := new TestClass
Test TestClass.smeth() "," TestClass.sprop
Test x.imeth() "," x.iprop
Test TestClass.HasMethod("smeth") TestClass.HasProperty("sprop")
Test TestClass.HasMethod("imeth") TestClass.HasProperty("iprop")
Test x.HasMethod("smeth") x.HasProperty("sprop")
Test x.HasMethod("imeth") x.HasProperty("iprop")
return
class TestClass extends Object {
    class _static {
        smeth() {
            return "static method"
        }
        sprop {
            get {
                return "static property"
            }
        }
    }
    imeth() {
        return "instance method"
    }
    iprop {
        get {
            return "instance property"
        }
    }
    static _ := MetaClass(TestClass)
}

TestSubClass:  ; FIXME: Currently fails because base.x() can't find x in the base (or _static has no base).
Test TestSubClass.smeth()
x := new TestSubClass
Test x.imeth()
return
class TestSubClass extends TestClass {
    class _static {
        smeth() {
            return base.smeth() " (subclassed)"
        }
    }
    imeth() {
        return base.imeth() " (subclassed)"
    }
    static _ := MetaClass(TestSubClass)
}

TestDefineMeth:
x := new CDM, y := new CDM
x.name := "x", y.name := "y"
x.DefineMethod("meth", Func("Test_call"))
Test x.HasMethod("meth") (x.meth="") " " x.meth(1)
Test y.HasMethod("meth") CDM.HasMethod("meth")
CDM.DefineMethod("me2", Func("Test_call"))
Test x.HasMethod("me2") y.HasMethod("me2") CDM.HasMethod("me2")
Test CDM.me2(2)
CDM.Prototype.DefineMethod("me3", Func("Test_call"))
Test x.HasMethod("me3") y.HasMethod("me3") CDM.HasMethod("me3")
Test x.me3(3) " " y.me3(4)
CDM.Prototype.DefineProperty("meth", {get: Func("Test_get_method").Bind("meth")})
Test x.meth.Call(5) " " x.meth(6)
return
Test_call(this, arg:="") {
    return this.name ".called(" arg ")"
}
Test_get_method(name, this) {
    return ObjBindMethod(this, name)
}
class CDM extends Object {
    static _ := MetaClass(CDM)
}

TestDefineProp:
x := new CDP, y := new CDP
x.DefineProperty("pg", {get: Func("Test_get").Bind("pg")})
Test x.pg " " (x.pg := 100) " " x.pg
x.DefineProperty("pgs", {get: Func("Test_get").Bind("pgs"), set: Func("Test_set").Bind("pgs")})
Test x.pgs " " (x.pgs := 200) " " x.pgs
x.defineProperty("ps", {set: Func("Test_set").Bind("ps")})
Test x.ps " " (x.ps := 300) " " x.ps
Test y.pg
Test x.HasProperty("pg") y.HasProperty("pg") CDP.HasProperty("pg")
CDP.DefineProperty("sprop", {get: Func("Test_get").Bind("sprop")})
CDP.prototype.DefineProperty("iprop", {get: Func("Test_get").Bind("iprop")})
Test CDP.sprop "," CDP.HasProperty("sprop")
Test x.sprop "," x.HasProperty("sprop")
Test CDP.iprop "," CDP.HasProperty("iprop")
Test x.iprop "," y.iprop "," x.HasProperty("iprop")
return
Test_get(arg1, this) {
    return arg1 "(" this._[arg1] ")"
}
Test_set(arg1, this, value) {
    return arg1 " := " value
}
class CDP extends Object {
    static _ := MetaClass(CDP)
}

TestHasMethod:
Test Object.HasMethod('HasMethod') TestHasMethod.HasMethod('HasMethod')
x := new TestHasMethod
Test x.HasMethod('meth') TestHasMethod.HasMethod('meth')
x.adhocprop := 2
Test x.HasMethod('prop') x.HasMethod('initprop') x.HasMethod('adhocprop')
return
class TestHasMethod extends Object {
    meth() {
        MsgBox "meth"
    }
    prop {
        get {
            return 1
        }
    }
    initprop := 1
    static _ := MetaClass(TestHasMethod)
}

TestHasProp:
Test Object.HasProperty('HasProperty') Object.HasMethod('HasProperty')
Test TestHasProp.HasMethod('HasProperty')
Test TestHasProp.HasProperty('propget')
x := new TestHasProp
Test x.HasProperty('propget') x.HasProperty('propset') x.HasProperty('propgetset')
x.adhocprop := 2
Test x.HasProperty('initprop') x.HasProperty('adhocprop')
Test x.HasKey('initprop') x.HasKey('adhocprop')
Test ObjHasKey(x, 'initprop') ObjHasKey(x, 'adhocprop')
Test x.HasProperty('meth') x.HasProperty('noprop') x.HasProperty(1)
return
class TestHasProp extends Object {
    initprop := 1
    propget {
        get {
            return 10
        }
    }
    propset {
        set {
            D "propset := " value
            return 20
        }
    }
    propgetset {
        get {
            return 30
        }
        set {
            D "propgetset := " value
            return 40
        }
    }
    meth() {
        MsgBox "meth"
    }
    static _ := MetaClass(TestHasProp)
}

Test(v) {
    e := Exception('', -1)
    s := ''
    Loop Read, e.File {
        if A_Index = e.Line {
            s := A_LoopReadLine
            break
        }
    }
    D s ' => ' v
}