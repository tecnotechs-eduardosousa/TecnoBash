<?php
error_reporting(E_ALL);
ini_set('display_errors', 'On');

define ( 'ROOT_PATH', dirname ( dirname ( dirname ( dirname ( __FILE__ ) ) ) ) );

//==========================================================================================
$ambientes = array('desenvolvimento');
//==========================================================================================
chdir(ROOT_PATH . '/extras');

chdir(dirname(__FILE__));
//==========================================================================================
$crea = $argv[1];

$uf = strtolower(substr($argv[1], 4));

$ini = array(
	"url_base_adapt" => "http://localhost:81",
	"url_base_servicos" => "http://localhost:82",
	"crea" => "CREA$crea",
	"ambiente" => "desenvolvimento",
);

if($crea) {
	$xmlSitac = simplexml_load_file(ROOT_PATH . "/extras/config_adapt/config.xml");
	$xmlServicos = simplexml_load_file(ROOT_PATH . "/extras/config_servicos/config.xml");

	$urlSitac = $ini["url_base_adapt"];
	$urlServicos = $ini["url_base_servicos"];

	$tags = array(
		"endereco.rpt.boleto" => $urlSitac,
		"licenca.end.pesquisa" => sprintf("%s/publico/", $urlSitac),
		"art.end.pesquisa" => sprintf("%s/publico/", $urlSitac),
		"endereco.url" => $urlSitac,
		"endereco.areaservicos" => $urlServicos,
		"webservice.minerva" => sprintf("%s/app/webservices/server.webservice.min3rva.officeweb.crea.php", $urlSitac),
		"session.timeout" => "20000",
		"captcha.login" => "N",
        "mail.host" => "",
        "mail.porta" => "",
		"mail.fromName" => "",
		"mail.usuario" => "",
		"mail.senha" => "",
		"mail.SMTPAuth" => "",
        "mail.SMTPSecure" => ""
    );


	foreach($tags as $key => $value) {
		$xmlSitac->org->{$key} = $value;
		$xmlServicos->org->{$key} = $value;
	}

	// avulsas
	if($xmlSitac->org->{'webservices.registro.boleto'}->{'bb'}) {
		@$xmlSitac->org->{'webservices.registro.boleto'}->{'bb'}->{'permite'} = 'N';
	}

	if($xmlSitac->org->{'webservices.registro.boleto'}->{'caixa'}) {
		@$xmlSitac->org->{'webservices.registro.boleto'}->{'caixa'}->{'permite'} = 'N';
	}
	
	if($xmlServicos->org->{'webservices.registro.boleto'}->{'bb'}) {
		@$xmlServicos->org->{'webservices.registro.boleto'}->{'bb'}->{'permite'} = 'N';
	}

	if($xmlServicos->org->{'webservices.registro.boleto'}->{'caixa'}) {
		@$xmlServicos->org->{'webservices.registro.boleto'}->{'caixa'}->{'permite'} = 'N';
	}

	// aplica as mudancas
	$xmlSitac->asXML(ROOT_PATH . "/extras/config_adapt/config.xml");
	$xmlServicos->asXML(ROOT_PATH . "/extras/config_servicos/config.xml");

    //verifica se esta linkado o config, senao copia
    $config_adapt = ROOT_PATH . "/adapt/config";
    $config_servicos = ROOT_PATH . "/servicos/config";

    if(file_exists($config_adapt)) {
        if(!is_link($config_adapt)) {
            $config_file_adapt = ROOT_PATH . "/extras/config_adapt/config.xml";
            $config_file_servicos = ROOT_PATH . "/extras/config_servicos/config.xml";

            copy($config_file_adapt, $config_adapt . '/config.xml');
            copy($config_file_servicos, $config_servicos. '/config.xml');
        }
    }

}

?>