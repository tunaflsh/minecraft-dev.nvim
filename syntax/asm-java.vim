if exists("b:current_syntax")
  finish
endif

syntax case match

" Comments
syntax match asmJavaComment "//.*$"
syntax region asmJavaComment start="/\*" end="\*/"

" Strings and escaped content
syntax region asmJavaString start=+"+ skip=+\\\\\|\\"+ end=+"+
syntax match asmJavaEscape "\\\\." contained

" Numeric constants, including javap's #constant-pool references.
syntax match asmJavaNumber "\(^\|\W\)\zs#\=\d\+\ze\($\|\W\)"

" javap-style labels and OW2 ASM-style label names.
syntax match asmJavaLabel "^\s*\d\+\ze:"
syntax match asmJavaLabel "^\s*L\d\+"
syntax match asmJavaCodeLabel "\<Code:"

" OW2 ASM / Jasmin-ish directives.
syntax match asmJavaDirective "^\s*\.\%(class\|super\|implements\|field\|method\|end\|limit\|source\|signature\|throws\|catch\|annotation\|attribute\|inner\|outer\|enum\)\>"

" Java modifiers and declaration terms.
syntax keyword asmJavaModifier
      \ public private protected static final abstract native synchronized
      \ transient volatile interface enum strictfp synthetic deprecated
      \ bridge varargs module open requires exports opens uses provides

syntax keyword asmJavaJavaKeyword
      \ class interface void boolean byte char short int long float double

syntax case ignore

" Object creation.
syntax keyword asmJavaNew new newarray anewarray multianewarray

" Field access.
syntax keyword asmJavaFieldAccess
      \ getfield getstatic putfield putstatic

" Loads and stores.
syntax keyword asmJavaLoad
      \ aaload baload caload daload faload iaload laload saload
      \ aload aload_0 aload_1 aload_2 aload_3
      \ iload iload_0 iload_1 iload_2 iload_3
      \ lload lload_0 lload_1 lload_2 lload_3
      \ fload fload_0 fload_1 fload_2 fload_3
      \ dload dload_0 dload_1 dload_2 dload_3

syntax keyword asmJavaStore
      \ aastore bastore castore dastore fastore iastore lastore sastore
      \ astore astore_0 astore_1 astore_2 astore_3
      \ istore istore_0 istore_1 istore_2 istore_3
      \ lstore lstore_0 lstore_1 lstore_2 lstore_3
      \ fstore fstore_0 fstore_1 fstore_2 fstore_3
      \ dstore dstore_0 dstore_1 dstore_2 dstore_3

" Invocation.
syntax keyword asmJavaCall
      \ invokeinterface invokespecial invokestatic invokevirtual invokedynamic

" Return instructions.
syntax keyword asmJavaReturn
      \ areturn dreturn freturn ireturn lreturn return ret

" Every remaining JVM instruction.
syntax keyword asmJavaInstruction
      \ aconst_null arraylength athrow
      \ bipush breakpoint checkcast
      \ d2f d2i d2l dadd dcmpg dcmpl dconst_0 dconst_1 ddiv dmul dneg
      \ drem dsub
      \ dup dup_x1 dup_x2 dup2 dup2_x1 dup2_x2
      \ f2d f2i f2l fadd fcmpg fcmpl fconst_0 fconst_1 fconst_2 fdiv fmul
      \ fneg frem fsub
      \ goto goto_w
      \ i2b i2c i2d i2f i2l i2s iadd iand iconst_m1 iconst_0 iconst_1
      \ iconst_2 iconst_3 iconst_4 iconst_5 idiv if_acmpeq if_acmpne
      \ if_icmpeq if_icmpge if_icmpgt if_icmple if_icmplt if_icmpne
      \ ifeq ifge ifgt ifle iflt ifne ifnonnull ifnull iinc imul ineg
      \ instanceof ior irem ishl ishr isub iushr ixor
      \ jsr jsr_w
      \ l2d l2f l2i ladd land lcmp lconst_0 lconst_1 ldc ldc_w ldc2_w
      \ ldiv lmul lneg lookupswitch lor lrem lshl lshr lsub lushr lxor
      \ monitorenter monitorexit nop
      \ pop pop2
      \ sipush swap tableswitch wide

syntax case match

highlight default link asmJavaComment Comment
highlight default link asmJavaString String
highlight default link asmJavaEscape SpecialChar
highlight default link asmJavaNumber Number
highlight default link asmJavaLabel Label
highlight default link asmJavaCodeLabel Label
highlight default link asmJavaDirective PreProc
highlight default link asmJavaModifier StorageClass
highlight default link asmJavaJavaKeyword Type
highlight default link asmJavaNew Keyword
highlight default link asmJavaFieldAccess StorageClass
highlight default link asmJavaLoad Identifier
highlight default link asmJavaStore Special
highlight default link asmJavaCall Function
highlight default link asmJavaReturn Statement
highlight default link asmJavaInstruction Keyword

let b:current_syntax = "asm-java"
