package lexlogic.lexlogic.service;

import lexlogic.lexlogic.entity.Insurer;
import lexlogic.lexlogic.repository.InsurerRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class InsurerService {

    private final InsurerRepository insurerRepository;

    public InsurerService(InsurerRepository insurerRepository){
        this.insurerRepository = insurerRepository;
    }

    public List<Insurer> getAllInsurers(){
        return insurerRepository.findAll();
    }
}
