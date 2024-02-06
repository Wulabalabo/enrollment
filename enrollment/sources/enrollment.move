module enrollment::enrollment {
    use sui::transfer;
    use sui::object::{Self, UID, ID};
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};
    use std::string::{String, from_ascii};
    use std::ascii;
    use std::vector;

    struct Session has key, store {
        id: UID,
        name: String,
        cadets: Table<address,String>,
        open:bool
    }

    struct Cadet has key {
        id:UID,
        name:String,
        github:String,
        session:ID
    }

    struct InstructorCap has key {id: UID}

    const ESessionNotOpen:u64 = 0;
    const EAlreadyEnrolled:u64 = 1;

    fun init(ctx: &mut TxContext) {
        transfer::transfer(InstructorCap{
            id: object::new(ctx)
        },tx_context::sender(ctx));
    }

    public entry fun cadet_enrollment(session:&mut Session, name:vector<u8>,github:vector<u8>,ctx: &mut TxContext) {
        
        let cadet_name =  internal_enrallment(session, name, ctx);
        let cadet_github = from_ascii(ascii::string(github));

        
        let cadet =Cadet {
            id: object::new(ctx),
            name: cadet_name,
            github: cadet_github,
            session: object::id(session)};

        
        transfer::transfer(cadet,tx_context::sender(ctx));
    }


    public entry fun update_table(_:&Cadet,session: &mut Session, name: vector<u8>,ctx:&mut TxContext){
        let cadet_name = from_ascii(ascii::string(name));
        table::remove(&mut session.cadets,tx_context::sender(ctx));
        internal_enrallment(session, name, ctx);
    }

    //=== Admin ===
    public entry fun new_instructor(_:&InstructorCap,recipient:address,ctx: &mut TxContext) {
        transfer::transfer(InstructorCap{
            id: object::new(ctx)
        },recipient);
    }

    public entry fun new_session(_:&InstructorCap,name:String,ctx: &mut TxContext) {
        transfer::transfer(Session{
            id: object::new(ctx),
            name: name,
            cadets: table::new(ctx),
            open: true
        },tx_context::sender(ctx));
    }

    public entry fun toggle_session(session:&mut Session,ctx: &mut TxContext) {
        session.open = !session.open;
    }

    //=== Internal ===
    fun internal_enrallment(session:&mut Session, name:vector<u8>,ctx: &mut TxContext):String {
        assert!(session.open, ESessionNotOpen);
        assert!(table::contains(&session.cadets,tx_context::sender(ctx)), EAlreadyEnrolled);        
        let cadet_name = from_ascii(ascii::string(name));
        table::add(&mut session.cadets,tx_context::sender(ctx),cadet_name);
        cadet_name
    }

}