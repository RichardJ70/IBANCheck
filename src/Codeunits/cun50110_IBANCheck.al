codeunit 50110 "IBAN Check"
{
    procedure GetIBANandSWIFTCode(PcodIBAN: code[50]; var PcodSWIFT: Code[20]; var PtxtBankName: text[50]) myBoolean: Boolean;
    var
        GLSetup: Record "General Ledger Setup";
        Client: HttpClient;
        Response: HttpResponseMessage;
        JSON: Text;
        jsonObj: JsonObject;
        IBANToken: JsonToken;
        bankDataToken: JsonToken;
        DataURL: Text;
        ValidText: Text;
        BICText: Text;
        ErrText001: Label 'IBAN service endpoint %1 is invalid.';
        ApplMgt: Codeunit 9015;

    begin
        if PcodIBAN = '' then
            exit(false);

        GLSetup.Get;
        GLSetup.TestField("IBAN Validation Service");
        DataURL := GLSetup."IBAN Validation Service" + '/' + PcodIBAN + '?getBIC=true&validateBankCode=true';
        //https://openiban.com/validate/IBAN_NUMBER?getBIC=true&validateBankCode=true
        Client.Get(DataURL, Response); //Reads the response content from the Azure function
        Response.Content.ReadAs(JSON);
        if not jsonObj.ReadFrom(JSON) then
            error(ErrText001);
        if jsonObj.get('valid', IBANToken) then begin
            ValidText := IBANToken.AsValue().AsText();
            if jsonObj.get('bankData', IBANToken) then begin
                IBANToken.SelectToken('$.bic', bankDataToken);
                PcodSWIFT := bankDataToken.AsValue().AsCode();
                IBANToken.SelectToken('$.name', bankDataToken);
                PtxtBankName := bankDataToken.AsValue().AsText();
            end;
        end;
        exit(true);
    end;


}