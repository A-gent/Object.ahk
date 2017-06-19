
class Object
{
    ; Data store
    ; _ := Object_v()
    
    class _static
    {
        new(p*) {
            return new this(p*)
        }
    }
    
    is(type) {
        return this is type
    }
    
    HasProperty(name) {
        cm := ObjGetBase(this)
        return isObject(cm.m.get[name] || cm.m.set[name])
            || ObjHasKey(this._, name)
            ; || ObjHasKey(this, name)
    }
    HasMethod(name) {
        cm := ObjGetBase(this)
        return isObject(cm.m.call[name])
    }
    
    DefineProperty(name, prop) {
        if !isObject(prop) || !(prop.get || prop.set)
            throw Exception("Invalid parameter #2", -2, prop)
        cm := Own_Meta(this)
        Class_Members_DefProp(cm.m, name, prop)
    }
    
    DefineMethod(name, func) {
        if !isObject(func)
            throw Exception("Invalid parameter #2", -2, func)
        cm := Own_Meta(this)
        Class_Members_DefMeth(cm.m, name, func)
    }
    
    ; Standard object methods
    Delete(p*) {
        return ObjDelete(this._, p*)
    }
    SetCapacity(p*) {
        return ObjSetCapacity(this._, p*)
    }
    GetCapacity(p*) {
        return ObjGetCapacity(this._, p*)
    }
    GetAddress(p) {
        return ObjGetAddress(this._, p)
    }
    HasKey(p) {
        return ObjHasKey(this._, p)
    }
    Clone() {
        return {_: ObjClone(this._), base: this.base}
    }
    _NewEnum() {
        return ObjNewEnum(this._)
    }
    
    static _ := MetaClass(Object)
}

class Class extends Object
{
    is(type) {
        if isObject(type)
            return type = Class || type = Object
        return this is type
    }
}

Value__call(value, n, p*) {
    static _ := ("".base.is := Func("Value__call"), 0)
    if n = "is"
        return value is p[1]
}

class Array extends Object
{
    Length {
        get {
            return ObjLength(this._)
        }
        set {
            if !(value is 'integer')
                throw Exception("Invalid value", -1, value)
            n := ObjLength(this._)
            if value = n
                return n
            if value < n {
                this.Delete(value + 1, n)
                n := ObjLength(this._)
            }
            else {
                Loop value - n
                    ObjRawSet(this._, ++n, "")
            }
            return ObjLength(this._)
        }
    }
    
    _NewEnum() {
        return new Array.Enumerator(this)
    }
    
    class Enumerator
    {
        __new(arr) {
            this._ := arr._
        }
        Next(ByRef a, ByRef b:="") {
            if IsByRef(b) {
                this.e := ObjNewEnum(this._)
                this.Next := this.base.Next2
            }
            else {
                this.Next := this.base.Next1
                this.n := 0
            }
            return this.Next(a, b)
        }
        Next1(ByRef a) {
            a := this._[++this.n]
            return this.n <= this._.Length()
        }
        Next2(ByRef a, ByRef b) {
            return this.e.Next(a, b)
        }
    }
    
    static _ := MetaClass(Array)
}

Object__new_(cm, f, this) {
    self := Object_v()
    ; This reuses the original object for data storage, since it already
    ; contains the ad hoc properties which were created in __init.
    ; FIXME: It's probably better to have property-assignment semantics,
    ;  not direct-to-data (i.e. property setters should be called).
    self._ := this
    self.base := cm
    ObjSetBase(this, "")
    (f) && f.call(self)
    return self
}
Object__init_(f, this) {
    f.call(this)
}
Object__get_(m, this, k, p*) {
    if f := m[k]
        return f.call(this, p*)
    return this._[k, p*]
}
Object__set_(m, this, k, p*) {
    if f := m[k]
        return f.call(this, p*)
    value := p.Pop()
    return this._[k, p*] := value
}
Object__call_(m, this, k, p*) {
    if f := m[k]
        return f.call(this, p*)
    throw Exception("No such method", -2, k)
}

class Class_Meta_Key {
}
Class_Meta(cls) {
    if ObjHasKey(cls, Class_Meta_Key)
        return cls[Class_Meta_Key]
    throw Exception("MetaClass has not been called for class " cls.__class, -1)
}

Class_Meta_new(m) {
    cm := Object_v()
    cm.__get := Func("Object__get_").Bind(m.get)
    cm.__set := Func("Object__set_").Bind(m.set)
    cm.__call := Func("Object__call_").Bind(m.call)
    cm.m := m
    return cm
}

Own_Meta(this) {
    cm := ObjGetBase(this)  ; It is assumed that 'this' is a properly constructed Object, with a meta-object.
    if cm.owner == &this
        return cm
    ; else: cm is shared.
    m := Class_Members_new()
    tm := Class_Meta_new(m)
    tm.owner := &this
    Class_Members_SetBase(m, cm)
    ObjSetBase(this, tm)
    return tm
}

Object_ReturnArg1(arg1) {
    return arg1
}

Object_Throw(message, what) {
    throw Exception(message, what)
}

Object_SetBase(this, newbase) {
    if newbase is Object && ObjHasKey(newbase, "__Class") || newbase = Object
        ObjSetBase(this, Class_Meta(newbase))
    else
        ObjSetBase(this, newbase)
    return newbase
}

class Class_Members_Key {
}
Class_Members_new() {
    m := Object_v()
    m.get := Object_v()
    m.set := Object_v()
    m.call := Object_v()
    ObjRawSet(m.get, "base", "")
    ObjRawSet(m.set, "base", "")
    ObjRawSet(m.call, "base", "")
    return m
}
Class_Members_SetBase(m, b) {
    bm := Class_Members(b)
    ObjSetBase(m.get, bm.get)
    ObjSetBase(m.set, bm.set)
    ObjSetBase(m.call, bm.call)
}
Class_Members_DefProp(m, name, prop) {
    (get := prop.get) && (m.get[name] := get)
    (set := prop.set) && (m.set[name] := set)
}
Class_Members_DefMeth(m, name, func) {
    m.call[name] := func
}
Class_Members(cls) {
    if ObjHasKey(cls, Class_Members_Key)
        return cls[Class_Members_Key]
    ObjRawSet(cls, Class_Members_Key, m := Class_Members_new())
    if bcls := ObjGetBase(cls)
        Class_Members_SetBase(m, bcls)
    e := ObjNewEnum(cls)
    while e.Next(k, v) {
        if type(v) = "Func" {  ; Not isFunc() - don't want func NAMES, only true methods.
            Class_Members_DefMeth(m, k, v)
        }
        else if type(v) = "Property" {
            Class_Members_DefProp(m, k, v)
        }
        else {
            ; Inherit static variables?
        }
    }
    return m
}

Array(p*) {
    a := Object_v()
    a._ := p
    a.base := Class_Meta(Array)
    return a
}

Object_v(p*) {
    return p
}

ForEachDelete(enumerate, deleteFrom) {
    e := ObjNewEnum(enumerate)
    while e.Next(k)
        ObjDelete(deleteFrom, k)
}

Class_DeleteMembers(cls, m) {
    ForEachDelete(m.call, cls)
    ForEachDelete(m.get, cls)
    ForEachDelete(m.set, cls)
}

MetaClass(cls) {
    ; Construct meta-object for instance prototype.
    m := Class_Members(cls)
    if !m.get["base"]
        m.get["base"] := Func("Object_ReturnArg1").Bind(cls)
    if !m.set["base"]
        m.set["base"] := Func("Object_SetBase")
    cm := Class_Meta_new(m)
    cm.base := cls  ; For type identity ('is').
    ObjRawSet(cls, Class_Meta_Key, cm)
    ; Remove instance members from class object.
    Class_DeleteMembers(cls, cm.m)
    ; Construct meta-object for class/static members.
    if st := ObjDelete(cls, "_static") {
        m := Class_Members(st)
    }
    else {
        m := Class_Members_new()
    }
    Class_Members_SetBase(m, Class)
    data := Object_v()
    e := ObjNewEnum(cls)
    while e.Next(k, v) {
        if type(v) == "Class"  ; Nested class (static variables should be in _static).
            ObjRawSet(data, k, v)
    }
    ForEachDelete(data, cls)
    cls_base := ObjGetBase(cls)  ; cls.base won't work right now for subclasses of Object.
    m.get["base"] := Func("Object_ReturnArg1").Bind(cls_base)
    m.set["base"] := Func("Object_Throw").Bind("Base class cannot be changed", -2)
    ; mcm defines the interface of the class object (not instances).
    mcm := Class_Meta_new(m)
    mcm.owner := &cls
    ; cm defines the interface of the instances, and prototype provides
    ; a way to DefineProperty()/DefineMethod() for all instances, since
    ; MyClass.DefineXxx() defines a Xxx for the class itself (static).
    proto := Object_v()
    proto._ := Object_v()
    ObjSetBase(proto, cm)
    cm.owner := &proto
    ObjRawSet(cls, "prototype", proto)
    ; __new and __init must be set here because __call isn't called for them,
    ; and we need to do special stuff anyway.  These are called with 'this' set
    ; to the new instance, and shouldn't be callable by the script since __call
    ; would be called in those cases.
    ; mcm.__new := Func("Object__new_").Bind(cm, cm.m.call["__new"])  ; This is called on class.base because the instance won't have a meta-object until after this is called.
    ; if cm.m.call["__init"]
        ; mcm.__init := Func("Object__init_").Bind(cm.m.call["__init"])
    ; They're set on the class itself rather than mcm because base.__init()
    ; would otherwise cause infinite recursion.
    ObjRawSet(cls, "__new", Func("Object__new_").Bind(cm, cm.m.call["__new"]))
    if cm.m.call["__init"]
        ObjRawSet(cls, "__init", Func("Object__init_").Bind(cm.m.call["__init"]))
    mcm.base := cls_base  ; For type identity of instances ('is').
    ObjSetBase(cls, mcm)
    if st && st.__init {
        ; Currently var initializers use ObjRawSet(), but might refer to
        ; 'this' explicitly and therefore may require this._ to be set.
        ObjRawSet(cls, "_", data)
        st.__init.call(data)
    }
    return data  ; Caller stores this in cls._.
}


;
; Bad code! Version-dependent. Relies on undocumented stuff.
;

ObjGetBase(obj) {
    try
        ObjGetCapacity(obj) ; Type-check.
    catch
        throw Exception("Invalid parameter #1", -1, obj)
    if thebase := NumGet(&obj + 2*A_PtrSize)
        return Object(thebase)
}

ObjSetBase(obj, newbase) {
    try
        ObjGetCapacity(obj) ; Type-check.
    catch
        throw Exception("Invalid parameter #1", -1, obj)
    if newbase {
        if !isObject(newbase)
            throw Exception("Invalid parameter #2", -1, newbase)
        ObjAddRef(&newbase)
        newbase := &newbase
    }
    oldbase := NumGet(&obj, 2*A_PtrSize)
    NumPut(newbase, &obj, 2*A_PtrSize)
    if oldbase
        ObjRelease(oldbase)
}

Object(p*) {
    if p.Length() = 1 {
        return ComObject(0x4009, &(n := p[1]))[]
    }
    obj := new Object
    while p.Length() {
        value := p.Pop()
        key := p.Pop()
        obj[key] := value
    }
    return obj
}
